package phoenix_live_react_tooling;

import elixir.ElixirException;
import elixir.ElixirMap;
import elixir.ElixirString;
import elixir.Enum;
import elixir.File;
import elixir.Jason;
import elixir.Kernel;
import elixir.MapSet;
import elixir.Path;
import elixir.Regex;
import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.Term;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactDependency;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactPackagePlan;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactTopology;

private typedef ManagedPackageValue = {
	path:Array<String>,
	expected:Term,
	acceptedExisting:Array<Term>
}

private typedef ApplyAccumulator = {
	json:Term,
	owned:Term
}

private typedef RemoveAccumulator = {
	json:Term,
	retained:Array<String>
}

private typedef BrowserDependency = {
	name:String,
	version:String,
	fileReference:Null<String>
}

/** Deterministic ownership of the npm package values required by LiveReact. */
@:keep
@:native("HaxePhoenixLiveReact.Package")
class LiveReactPackage {
	static inline final OK:Atom = "ok";
	static inline final ERROR:Atom = "error";
	static inline final PRETTY:Atom = "pretty";
	static inline final ABSOLUTE:Atom = "absolute";
	static inline final PHOENIX:Atom = "phoenix";
	static inline final PHOENIX_HTML:Atom = "phoenix_html";
	static inline final PHOENIX_LIVE_VIEW:Atom = "phoenix_live_view";

	public static function plan(topology:LiveReactTopology, dependency:LiveReactDependency, existingManifest:Term,
			mixDependencyPaths:Term):LiveReactPackagePlan {
		var content = File.readBang(topology.packageJson);
		var decoded = Jason.decodeResult(content);
		var decodedTag = tag(decoded);
		if (decodedTag != OK)
			return Kernel.raiseValue("cannot parse " + topology.packageJson + ": " + ElixirException.message(Kernel.elemAs(decoded, 1)));
		var value = Kernel.elem(decoded, 1);
		if (!Kernel.isMap(value))
			return Kernel.raiseValue(topology.packageJson + " must contain a JSON object. No writes occurred.");
		var browserDependencies = resolvedBrowserDependencies(topology, mixDependencyPaths);
		validateBrowserDependencies(topology, value, browserDependencies);

		var existingOwned = existingManifest == null ? MapSet.new_() : MapSet.fromValues(manifestPackageKeys(existingManifest));
		var initial:ApplyAccumulator = {json: value, owned: existingOwned};
		var specs = managedValues(dependency.npmReference, browserDependencies);
		var accumulated = Enum.reduce(specs, initial, function(spec:ManagedPackageValue, state:ApplyAccumulator):ApplyAccumulator {
			var dotted = Enum.join(spec.path, ".");
			var fetched = fetchJsonPath(state.json, spec.path, 0);
			var fetchedTag = tag(fetched);
			if (fetchedTag == ERROR)
				return {json: putJsonPath(state.json, spec.path, 0, spec.expected), owned: MapSet.put(state.owned, dotted)};
			var actual = Kernel.elem(fetched, 1);
			if (actual == spec.expected)
				return state;
			if (!MapSet.member(state.owned, dotted) && Enum.member(spec.acceptedExisting, actual))
				return state;
			return Kernel.raiseValue(topology.packageJson
				+ " "
				+ dotted
				+ " conflicts with the managed value. Found "
				+ Kernel.inspect(actual)
				+ ", expected "
				+ Kernel.inspect(spec.expected)
				+ ". No writes occurred. Preserve the existing value and use manual integration, or remove it before retrying.");
		});
		var options:KeywordList<Term> = [{_0: PRETTY, _1: true}];
		return {
			content: Enum.join([Jason.encodeStrictWithKeywordOptions(accumulated.json, options), ""], "\n"),
			ownedKeys: Enum.sort(MapSet.toList(accumulated.owned)),
			ownedValues: ownedPackageValues(accumulated.json, accumulated.owned, specs)
		};
	}

	public static function remove(topology:LiveReactTopology, manifest:Term):LiveReactPackagePlan {
		var value = Jason.decodeStrict(File.readBang(topology.packageJson));
		if (!Kernel.isMap(value))
			return Kernel.raiseValue(topology.packageJson + " must contain a JSON object. No writes occurred.");
		var owned = MapSet.fromValues(manifestPackageKeys(manifest));
		var handUsage = handOwnedBrowserPackages(topology);
		var npmReference:String = ElixirMap.fetchBangTerm(manifest, "npmReference");
		var packageValues = manifestPackageValues(manifest);
		var initial:RemoveAccumulator = {json: value, retained: []};
		var accumulated = Enum.reduce(legacyManagedValues(npmReference), initial,
			function(spec:ManagedPackageValue, state:RemoveAccumulator):RemoveAccumulator {
				var dotted = Enum.join(spec.path, ".");
				if (!MapSet.member(owned, dotted))
					return state;
				var fetched = fetchJsonPath(state.json, spec.path, 0);
				var fetchedTag = tag(fetched);
				if (fetchedTag == ERROR)
					return state;
				var actual = Kernel.elem(fetched, 1);
				var expected:Term = ElixirMap.getTypedWithDefault(packageValues, dotted, spec.expected);
				if (actual != expected)
					return Kernel.raiseValue("cannot remove package.json " + dotted + ": owned value drifted to " + Kernel.inspect(actual)
						+ ". No writes occurred.");
				var packageName = spec.path[spec.path.length - 1];
				return MapSet.member(handUsage, packageName) ? {
					json: state.json,
					retained: Enum.concatTwo([dotted], state.retained)
				} : {json: deleteJsonPath(state.json, spec.path, 0), retained: state.retained};
			});
		var options:KeywordList<Term> = [{_0: PRETTY, _1: true}];
		return {
			content: Enum.join([Jason.encodeStrictWithKeywordOptions(accumulated.json, options), ""], "\n"),
			retainedKeys: Enum.sort(accumulated.retained)
		};
	}

	/** Historical schema-one manifests predate packageValues and owned these exact defaults. */
	static function legacyManagedValues(npmReference:String):Array<ManagedPackageValue> {
		return managedValues(npmReference, [
			{name: "phoenix", version: "1.7.24", fileReference: null},
			{name: "phoenix_html", version: "4.3.0", fileReference: null},
			{name: "phoenix_live_view", version: "0.20.17", fileReference: null}
		]);
	}

	static function ownedPackageValues(json:Term, owned:Term, specs:Array<ManagedPackageValue>):Term {
		return Enum.reduce(specs, ElixirMap.new_(), function(spec:ManagedPackageValue, values:Term):Term {
			var dotted = Enum.join(spec.path, ".");
			if (!MapSet.member(owned, dotted))
				return values;
			var fetched = fetchJsonPath(json, spec.path, 0);
			return tag(fetched) == ERROR ? values : ElixirMap.putTerm(values, dotted, Kernel.elem(fetched, 1));
		});
	}

	static function managedValues(npmReference:String, browserDependencies:Array<BrowserDependency>):Array<ManagedPackageValue> {
		var phoenix = browserDependencies[0];
		var phoenixHtml = browserDependencies[1];
		var liveView = browserDependencies[2];
		return [
			{path: ["private"], expected: true, acceptedExisting: []},
			{path: ["type"], expected: "module", acceptedExisting: []},
			{
				path: ["scripts", "assets:dev"],
				expected: "vite --host 127.0.0.1 --port 5173 --strictPort --logLevel warn",
				acceptedExisting: []
			},
			{path: ["scripts", "assets:build"], expected: "vite build", acceptedExisting: []},
			{path: ["dependencies", "live_react"], expected: npmReference, acceptedExisting: []},
			{
				path: ["dependencies", "phoenix"],
				expected: phoenix.version,
				acceptedExisting: acceptedFileReference(phoenix)
			},
			{
				path: ["dependencies", "phoenix_html"],
				expected: phoenixHtml.version,
				acceptedExisting: acceptedFileReference(phoenixHtml)
			},
			{
				path: ["dependencies", "phoenix_live_view"],
				expected: liveView.version,
				acceptedExisting: acceptedFileReference(liveView)
			},
			{path: ["dependencies", "react"], expected: "19.1.0", acceptedExisting: []},
			{path: ["dependencies", "react-dom"], expected: "19.1.0", acceptedExisting: []},
			{path: ["devDependencies", "@vitejs/plugin-react"], expected: "4.5.2", acceptedExisting: []},
			{path: ["devDependencies", "vite"], expected: "7.2.7", acceptedExisting: []}
		];
	}

	static function resolvedBrowserDependencies(topology:LiveReactTopology, paths:Term):Array<BrowserDependency> {
		return Enum.map(["phoenix", "phoenix_html", "phoenix_live_view"], function(name:String):BrowserDependency {
			var checkout = dependencyPath(paths, name);
			var packagePath = Path.joinTwo(checkout, "package.json");
			if (!File.regular(packagePath))
				return Kernel.raiseValue("cannot verify the resolved Mix checkout for "
					+ name
					+ ": "
					+ packagePath
					+ " is missing. Run `mix deps.get`, then retry. No writes occurred.");
			var packageJson = Jason.decodeStrict(File.readBang(packagePath));
			var packageName:Term = ElixirMap.get(packageJson, "name");
			var version:Term = ElixirMap.get(packageJson, "version");
			if (packageName != name || !Kernel.isBinary(version))
				return Kernel.raiseValue(packagePath + " must identify npm package " + name + " with a string version. No writes occurred.");
			return {
				name: name,
				version: version,
				fileReference: projectLocalFileReference(topology, checkout)
			};
		});
	}

	static function dependencyPath(paths:Term, name:String):String {
		var fetched = ElixirMap.fetchTerm(paths, name);
		if (tag(fetched) == ERROR) {
			var app:Atom = switch (name) {
				case "phoenix": PHOENIX;
				case "phoenix_html": PHOENIX_HTML;
				case _: PHOENIX_LIVE_VIEW;
			};
			fetched = ElixirMap.fetchTerm(paths, app);
		}
		if (tag(fetched) == ERROR)
			return Kernel.raiseValue("cannot find the resolved Mix checkout for " + name + ". Run `mix deps.get`, then retry. No writes occurred.");
		return Path.expand(Kernel.elemAs(fetched, 1));
	}

	static function projectLocalFileReference(topology:LiveReactTopology, checkout:String):Null<String> {
		var relativeToRoot = Path.relativeTo(checkout, topology.root);
		if (Path.typeAtom(relativeToRoot) == ABSOLUTE || relativeToRoot == ".." || ElixirString.startsWith(relativeToRoot, "../"))
			return null;
		var parents = topology.packageRootRelative == "." ? [] : Enum.map(Path.split(topology.packageRootRelative), function(_:String):String return "..");
		var relative = Path.join(Enum.concatTwo(parents, Path.split(relativeToRoot)));
		return "file:" + ElixirString.replace(relative, "\\", "/");
	}

	static function acceptedFileReference(dependency:BrowserDependency):Array<Term> {
		return dependency.fileReference == null ? [] : [dependency.fileReference];
	}

	static function validateBrowserDependencies(topology:LiveReactTopology, packageJson:Term, dependencies:Array<BrowserDependency>):Void {
		Enum.each(dependencies, function(dependency:BrowserDependency):Void {
			var fetched = fetchJsonPath(packageJson, ["dependencies", dependency.name], 0);
			if (tag(fetched) != ERROR) {
				var actual:Term = Kernel.elem(fetched, 1);
				var matchesFileReference = dependency.fileReference != null && actual == dependency.fileReference;
				if (actual != dependency.version && !matchesFileReference) {
					var repair = "Use " + Kernel.inspect(dependency.version);
					if (dependency.fileReference != null)
						repair += " or " + Kernel.inspect(dependency.fileReference);
					Kernel.raiseValue(dependency.name + " browser package is " + Kernel.toString(actual) + ", but the resolved Mix checkout is "
						+ dependency.version + ". " + repair + " in " + topology.packageJson + ", run npm install, then retry. No writes occurred.");
				}
			}
		});
	}

	static function fetchJsonPath(json:Term, path:Array<String>, index:Int):Term {
		if (!Kernel.isMap(json))
			return Kernel.raiseValue("package.json " + path[index - 1] + " must be an object, found " + Kernel.inspect(json) + ". No writes occurred.");
		var fetched = ElixirMap.fetchTerm(json, path[index]);
		var fetchedTag = tag(fetched);
		if (fetchedTag == ERROR)
			return ERROR;
		var value = Kernel.elem(fetched, 1);
		return index == path.length - 1 ? {_0: OK, _1: value} : fetchJsonPath(value, path, index + 1);
	}

	static function putJsonPath(json:Term, path:Array<String>, index:Int, value:Term):Term {
		var key = path[index];
		if (index == path.length - 1)
			return ElixirMap.putTerm(json, key, value);
		var child = ElixirMap.getTypedWithDefault(json, key, ElixirMap.new_());
		if (!Kernel.isMap(child))
			return Kernel.raiseValue("package.json " + key + " must be an object, found " + Kernel.inspect(child) + ". No writes occurred.");
		return ElixirMap.putTerm(json, key, putJsonPath(child, path, index + 1, value));
	}

	static function deleteJsonPath(json:Term, path:Array<String>, index:Int):Term {
		var key = path[index];
		if (index == path.length - 1)
			return ElixirMap.deleteTerm(json, key);
		var fetched = ElixirMap.fetchTerm(json, key);
		var fetchedTag = tag(fetched);
		if (fetchedTag == ERROR)
			return json;
		var child = Kernel.elem(fetched, 1);
		if (!Kernel.isMap(child))
			return json;
		var updated = deleteJsonPath(child, path, index + 1);
		return Kernel.mapSize(updated) == 0 ? ElixirMap.deleteTerm(json, key) : ElixirMap.putTerm(json, key, updated);
	}

	static function handOwnedBrowserPackages(topology:LiveReactTopology):Term {
		var managed = MapSet.fromValues([topology.viteConfig, topology.hooksFile, topology.registryFile]);
		var globs = [
			Path.joinTwo(topology.root, "assets/**/*.{js,jsx,ts,tsx,mjs,cjs}"),
			Path.joinTwo(topology.packageRoot, "*.{js,jsx,ts,tsx,mjs,cjs}")
		];
		var files = Enum.uniq(Enum.flatMap(globs, function(pattern:String):Array<String> return Path.wildcard(pattern)));
		files = Enum.filter(files, function(path:String):Bool {
			return !MapSet.member(managed, path) && !elixir.ElixirString.contains(path, "/node_modules/");
		});
		var imported = Enum.reduce(files, MapSet.new_(), function(path:String, packages:Term):Term {
			var source = File.readBang(path);
			var updated = maybeMarkPackage(packages, source, "live_react");
			updated = maybeMarkPackage(updated, source, "react");
			updated = maybeMarkPackage(updated, source, "react-dom");
			updated = maybeMarkPackage(updated, source, "vite");
			return maybeMarkPackage(updated, source, "@vitejs/plugin-react");
		});
		return retainRuntimePeers(imported);
	}

	/**
	 * A retained LiveReact browser import still mounts through React and ReactDOM.
	 * Keep that complete runtime dependency set even when JSX's automatic runtime
	 * means the hand-owned component does not spell those peer imports itself.
	 */
	static function retainRuntimePeers(packages:Term):Term {
		if (!MapSet.member(packages, "live_react"))
			return packages;
		return MapSet.put(MapSet.put(packages, "react"), "react-dom");
	}

	static function maybeMarkPackage(packages:Term, source:String, packageName:String):Term {
		var pattern = Regex.compileBang("(?:from\\s+|import\\s*\\(?\\s*)[\"']" + Regex.escape(packageName) + "(?:[\\/\"'])");
		return Regex.match(pattern, source) ? MapSet.put(packages, packageName) : packages;
	}

	static function manifestPackageKeys(manifest:Term):Array<String> {
		var managed:Term = ElixirMap.fetchBangTerm(manifest, "managed");
		return ElixirMap.fetchBangTerm(managed, "packageKeys");
	}

	static function manifestPackageValues(manifest:Term):Term {
		var managed:Term = ElixirMap.fetchBangTerm(manifest, "managed");
		return ElixirMap.getTypedWithDefault(managed, "packageValues", ElixirMap.new_());
	}

	static function tag(value:Term):Atom {
		return Kernel.isTuple(value) ? Kernel.elemAs(value, 0) : value;
	}
}
