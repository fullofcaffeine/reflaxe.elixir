package phoenix_live_react_tooling;

import elixir.ElixirException;
import elixir.ElixirMap;
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
	expected:Term
}

private typedef ApplyAccumulator = {
	json:Term,
	owned:Term
}

private typedef RemoveAccumulator = {
	json:Term,
	retained:Array<String>
}

/** Deterministic ownership of the npm package values required by LiveReact. */
@:keep
@:native("HaxePhoenixLiveReact.Package")
class LiveReactPackage {
	static inline final OK:Atom = "ok";
	static inline final ERROR:Atom = "error";
	static inline final PRETTY:Atom = "pretty";

	public static function plan(topology:LiveReactTopology, dependency:LiveReactDependency, existingManifest:Term):LiveReactPackagePlan {
		var content = File.readBang(topology.packageJson);
		var decoded = Jason.decodeResult(content);
		var decodedTag = tag(decoded);
		if (decodedTag != OK)
			return Kernel.raiseValue("cannot parse " + topology.packageJson + ": " + ElixirException.message(Kernel.elemAs(decoded, 1)));
		var value = Kernel.elem(decoded, 1);
		if (!Kernel.isMap(value))
			return Kernel.raiseValue(topology.packageJson + " must contain a JSON object. No writes occurred.");

		var existingOwned = existingManifest == null ? MapSet.new_() : MapSet.fromValues(manifestPackageKeys(existingManifest));
		var initial:ApplyAccumulator = {json: value, owned: existingOwned};
		var accumulated = Enum.reduce(managedValues(dependency.npmReference), initial,
			function(spec:ManagedPackageValue, state:ApplyAccumulator):ApplyAccumulator {
				var dotted = Enum.join(spec.path, ".");
				var fetched = fetchJsonPath(state.json, spec.path, 0);
				var fetchedTag = tag(fetched);
				if (fetchedTag == ERROR)
					return {json: putJsonPath(state.json, spec.path, 0, spec.expected), owned: MapSet.put(state.owned, dotted)};
				var actual = Kernel.elem(fetched, 1);
				if (actual == spec.expected)
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
			ownedKeys: Enum.sort(MapSet.toList(accumulated.owned))
		};
	}

	public static function remove(topology:LiveReactTopology, manifest:Term):LiveReactPackagePlan {
		var value = Jason.decodeStrict(File.readBang(topology.packageJson));
		if (!Kernel.isMap(value))
			return Kernel.raiseValue(topology.packageJson + " must contain a JSON object. No writes occurred.");
		var owned = MapSet.fromValues(manifestPackageKeys(manifest));
		var handUsage = handOwnedBrowserPackages(topology);
		var npmReference:String = ElixirMap.fetchBangTerm(manifest, "npmReference");
		var initial:RemoveAccumulator = {json: value, retained: []};
		var accumulated = Enum.reduce(managedValues(npmReference), initial, function(spec:ManagedPackageValue, state:RemoveAccumulator):RemoveAccumulator {
			var dotted = Enum.join(spec.path, ".");
			if (!MapSet.member(owned, dotted))
				return state;
			var fetched = fetchJsonPath(state.json, spec.path, 0);
			var fetchedTag = tag(fetched);
			if (fetchedTag == ERROR)
				return state;
			var actual = Kernel.elem(fetched, 1);
			if (actual != spec.expected)
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

	static function managedValues(npmReference:String):Array<ManagedPackageValue> {
		return [
			{path: ["private"], expected: true},
			{path: ["type"], expected: "module"},
			{path: ["scripts", "assets:dev"], expected: "vite --host 127.0.0.1 --port 5173 --strictPort --logLevel warn"},
			{path: ["scripts", "assets:build"], expected: "vite build"},
			{path: ["dependencies", "live_react"], expected: npmReference},
			{path: ["dependencies", "phoenix"], expected: "1.7.24"},
			{path: ["dependencies", "phoenix_html"], expected: "4.3.0"},
			{path: ["dependencies", "phoenix_live_view"], expected: "0.20.17"},
			{path: ["dependencies", "react"], expected: "19.1.0"},
			{path: ["dependencies", "react-dom"], expected: "19.1.0"},
			{path: ["devDependencies", "@vitejs/plugin-react"], expected: "4.5.2"},
			{path: ["devDependencies", "vite"], expected: "7.2.7"}
		];
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
		return Enum.reduce(files, MapSet.new_(), function(path:String, packages:Term):Term {
			var source = File.readBang(path);
			var updated = maybeMarkPackage(packages, source, "live_react");
			updated = maybeMarkPackage(updated, source, "react");
			updated = maybeMarkPackage(updated, source, "react-dom");
			updated = maybeMarkPackage(updated, source, "vite");
			return maybeMarkPackage(updated, source, "@vitejs/plugin-react");
		});
	}

	static function maybeMarkPackage(packages:Term, source:String, packageName:String):Term {
		var pattern = Regex.compileBang("(?:from\\s+|import\\s*\\(?\\s*)[\"']" + Regex.escape(packageName) + "(?:[\\/\"'])");
		return Regex.match(pattern, source) ? MapSet.put(packages, packageName) : packages;
	}

	static function manifestPackageKeys(manifest:Term):Array<String> {
		var managed:Term = ElixirMap.fetchBangTerm(manifest, "managed");
		return ElixirMap.fetchBangTerm(managed, "packageKeys");
	}

	static function tag(value:Term):Atom {
		return Kernel.isTuple(value) ? Kernel.elemAs(value, 0) : value;
	}
}
