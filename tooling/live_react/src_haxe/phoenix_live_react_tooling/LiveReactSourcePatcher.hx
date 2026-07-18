package phoenix_live_react_tooling;

import elixir.Code;
import elixir.ElixirMap;
import elixir.ElixirString;
import elixir.Enum;
import elixir.ErlangBinary;
import elixir.Kernel;
import elixir.List;
import elixir.Regex;
import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.Term;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactDependency;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactTopology;

private typedef RootScript = {
	final original:String;
	final startIndex:Int;
	final endIndex:Int;
	final indent:String;
}

/**
 * Deterministic source transforms for the PhoenixHx LiveReact lifecycle.
 *
 * Every transform validates ownership before returning changed text. Filesystem
 * publication remains the responsibility of `HaxeProjectPatch`.
 */
@:keep
@:native("HaxePhoenixLiveReact.SourcePatcher")
class LiveReactSourcePatcher {
	static inline final OK:Atom = "ok";
	static inline final ERROR:Atom = "error";
	static inline final MISSING:Atom = "missing";
	static inline final PRESENT:Atom = "present";
	static inline final NOMATCH:Atom = "nomatch";
	static inline final RETURN:Atom = "return";
	static inline final INDEX:Atom = "index";
	static inline final GLOBAL:Atom = "global";
	static inline final PARTS:Atom = "parts";
	static inline final TRIM:Atom = "trim";

	public static function markerSpecs():Array<Term> {
		return [
			{_0: "mix.exs", _1: "BEGIN reflaxe_elixir live_react_dependency", _2: "END reflaxe_elixir live_react_dependency"},
			{_0: "mix.exs", _1: "BEGIN reflaxe_elixir live_react_assets_setup", _2: "END reflaxe_elixir live_react_assets_setup"},
			{_0: "mix.exs", _1: "BEGIN reflaxe_elixir live_react_assets_build", _2: "END reflaxe_elixir live_react_assets_build"},
			{_0: "mix.exs", _1: "BEGIN reflaxe_elixir live_react_assets_deploy", _2: "END reflaxe_elixir live_react_assets_deploy"},
			{_0: "config/config.exs", _1: "BEGIN reflaxe_elixir live_react_config", _2: "END reflaxe_elixir live_react_config"},
			{_0: "config/dev.exs", _1: "BEGIN reflaxe_elixir live_react_vite_watcher", _2: "END reflaxe_elixir live_react_vite_watcher"},
			{_0: "config/dev.exs", _1: "BEGIN reflaxe_elixir live_react_vite_host", _2: "END reflaxe_elixir live_react_vite_host"},
			{_0: "assets/js/app.js", _1: "BEGIN reflaxe_elixir live_react_import", _2: "END reflaxe_elixir live_react_import"},
			{_0: "assets/js/app.js", _1: "BEGIN reflaxe_elixir live_react_hooks", _2: "END reflaxe_elixir live_react_hooks"},
			{_0: "assets/js/app.js", _1: "BEGIN reflaxe_elixir live_react_window_hooks", _2: "END reflaxe_elixir live_react_window_hooks"},
			{_0: "assets/js/app.js", _1: "BEGIN reflaxe_elixir live_react_hooks_property", _2: "END reflaxe_elixir live_react_hooks_property"},
			{_0: "root_layout", _1: "BEGIN reflaxe_elixir live_react_vite_assets", _2: "END reflaxe_elixir live_react_vite_assets"}
		];
	}

	public static function managedMarkers(topology:LiveReactTopology):Array<Term> {
		var markers = Enum.map(markerSpecs(), function(spec:Term):Term {
			var sourcePath:String = Kernel.elemAs(spec, 0);
			var path = sourcePath == "root_layout" ? elixir.Path.relativeTo(topology.rootLayout, topology.root) : sourcePath;
			var marker = ElixirMap.new_();
			marker = ElixirMap.putTerm(marker, "path", path);
			marker = ElixirMap.putTerm(marker, "begin", Kernel.elemAs(spec, 1));
			return ElixirMap.putTerm(marker, "end", Kernel.elemAs(spec, 2));
		});
		return Enum.sortBy(markers, function(marker:Term):String {
			return ElixirMap.getTyped(marker, "path") + "\n" + ElixirMap.getTyped(marker, "begin");
		});
	}

	public static function patchMixExs(content:String, topology:LiveReactTopology, dependency:LiveReactDependency, restores:Term):{_0:String, _1:Term} {
		validateFileMarkers(content, "mix.exs", "mix.exs");
		var updated = patchLiveReactDependency(content, dependency);
		var setup = patchAssetAlias(updated, "assets.setup", IntegrationCore.packageCommand(topology.packageRootRelative, "npm install --no-audit --no-fund"),
			"BEGIN reflaxe_elixir live_react_assets_setup", "END reflaxe_elixir live_react_assets_setup", "mix.assets.setup", restores);
		var build = patchAssetAlias(setup._0, "assets.build", IntegrationCore.packageCommand(topology.packageRootRelative, "npm run assets:build"),
			"BEGIN reflaxe_elixir live_react_assets_build", "END reflaxe_elixir live_react_assets_build", "mix.assets.build", setup._1);
		return patchAssetAlias(build._0, "assets.deploy", IntegrationCore.packageCommand(topology.packageRootRelative, "npm run assets:build"),
			"BEGIN reflaxe_elixir live_react_assets_deploy", "END reflaxe_elixir live_react_assets_deploy", "mix.assets.deploy", build._1);
	}

	public static function patchConfigExs(content:String, restores:Term):{_0:String, _1:Term} {
		var beginToken = "BEGIN reflaxe_elixir live_react_config";
		var endToken = "END reflaxe_elixir live_react_config";
		var desired = IntegrationCore.liveReactConfigLines();
		validateMarkerPairs(content, [{_0: beginToken, _1: endToken}], "config/config.exs");
		var replaced = ProjectPatch.replaceMarkerBlockLines(content, beginToken, endToken, desired);
		var replacedTag = tag(replaced);
		if (replacedTag == OK) {
			requireRestoreKey(restores, "config.trailingWhitespace");
			return {_0: Kernel.elemAs(replaced, 1), _1: restores};
		}
		if (replacedTag == ERROR)
			return Kernel.raiseValue("config/config.exs has a malformed LiveReact marker (" + Kernel.inspect(Kernel.elem(replaced, 1))
				+ "). No writes occurred.");
		if (Regex.match(rxWithOptions("^\\s*config\\s+:live_react\\b", "m"), content))
			return Kernel.raiseValue("config/config.exs already contains unowned LiveReact configuration. No writes occurred. Manual integration is required.");
		return {
			_0: appendMarkerBlock(content, beginToken, endToken, desired, "", "#"),
			_1: putRestore(restores, "config.trailingWhitespace", trailingWhitespace(content))
		};
	}

	public static function patchDevExs(content:String, topology:LiveReactTopology, restores:Term):{_0:String, _1:Term} {
		validateFileMarkers(content, "config/dev.exs", "config/dev.exs");
		var beginWatcher = "BEGIN reflaxe_elixir live_react_vite_watcher";
		var endWatcher = "END reflaxe_elixir live_react_vite_watcher";
		var watcherLine = IntegrationCore.viteWatcherLine(topology.packageRootRelative);
		var watcher = ProjectPatch.replaceMarkerBlockLines(content, beginWatcher, endWatcher, [watcherLine]);
		var watcherTag = tag(watcher);
		var watcherResult:{_0:String, _1:Term};
		if (watcherTag == OK) {
			watcherResult = {_0: Kernel.elemAs(watcher, 1), _1: restores};
		} else if (watcherTag == ERROR) {
			return Kernel.raiseValue("config/dev.exs has a malformed LiveReact Vite watcher marker ("
				+ Kernel.inspect(Kernel.elem(watcher, 1))
				+ "). No writes occurred.");
		} else {
			watcherResult = insertViteWatcher(content, watcherLine, restores);
		}

		var beginHost = "BEGIN reflaxe_elixir live_react_vite_host";
		var endHost = "END reflaxe_elixir live_react_vite_host";
		var hostLines = IntegrationCore.liveReactDevConfigLines();
		var host = ProjectPatch.replaceMarkerBlockLines(watcherResult._0, beginHost, endHost, hostLines);
		var hostTag = tag(host);
		if (hostTag == OK) {
			requireRestoreKey(watcherResult._1, "dev.trailingWhitespace");
			return {_0: Kernel.elemAs(host, 1), _1: watcherResult._1};
		}
		if (hostTag == ERROR)
			return Kernel.raiseValue("config/dev.exs has a malformed LiveReact host marker (" + Kernel.inspect(Kernel.elem(host,
				1)) + "). No writes occurred.");
		if (Regex.match(rxWithOptions("^\\s*config\\s+:live_react\\b", "m"), watcherResult._0))
			return Kernel.raiseValue("config/dev.exs already contains unowned LiveReact configuration. No writes occurred. Manual integration is required.");
		return {
			_0: appendMarkerBlock(watcherResult._0, beginHost, endHost, hostLines, "", "#"),
			_1: putRestore(watcherResult._1, "dev.trailingWhitespace", trailingWhitespace(watcherResult._0))
		};
	}

	public static function patchAppJs(content:String, restores:Term):{_0:String, _1:Term} {
		validateFileMarkers(content, "assets/js/app.js", "assets/js/app.js");
		return patchAppJsHooks(patchAppJsImport(content), restores);
	}

	public static function patchRootLayout(content:String, restores:Term):{_0:String, _1:Term} {
		var beginToken = "BEGIN reflaxe_elixir live_react_vite_assets";
		var endToken = "END reflaxe_elixir live_react_vite_assets";
		var restoreKey = "layout.appScript";
		validateMarkerPairs(content, [{_0: beginToken, _1: endToken}], "Phoenix root layout");
		var existingOriginal:Null<String> = ElixirMap.getTyped(restores, restoreKey);
		var desired = existingOriginal == null ? [] : rootAssetInnerLines(existingOriginal);
		var replaced = ProjectPatch.replaceMarkerBlockLines(content, beginToken, endToken, desired);
		var replacedTag = tag(replaced);
		if (replacedTag == OK) {
			if (existingOriginal == null)
				return Kernel.raiseValue(IntegrationCore.MANIFEST_FILENAME
					+ " is missing the original root-layout app script needed for recovery. No writes occurred.");
			return {_0: Kernel.elemAs(replaced, 1), _1: restores};
		}
		if (replacedTag == ERROR)
			return Kernel.raiseValue("Phoenix root layout has a malformed LiveReact assets marker ("
				+ Kernel.inspect(Kernel.elem(replaced, 1))
				+ "). No writes occurred.");
		if (ElixirString.contains(content, "LiveReact.Reload.vite_assets"))
			return
				Kernel.raiseValue("Phoenix root layout already contains an unowned LiveReact Vite asset wrapper. No writes occurred. Manual integration is required.");

		var script = findRootAppScript(content);
		var nextRestores = putRestore(restores, restoreKey, script.original);
		var lines = splitLines(content);
		var block = markerLinesWithSuffix(beginToken, endToken, rootAssetInnerLines(script.original), script.indent, "<%!--", "--%>");
		var updated = replaceLineRange(lines, script.startIndex, script.endIndex, Enum.join(block, "\n"));
		return {_0: Enum.join(updated, "\n"), _1: nextRestores};
	}

	public static function removeMixWiring(content:String, manifest:Term, topology:LiveReactTopology, restores:Term, retainLiveReact:Bool):String {
		var managed = mapGetTerm(manifest, "managed");
		var dependencyOwned:Bool = mapGet(managed, "dependencyOwned");
		var updated = if (dependencyOwned && retainLiveReact) {
			unwrapOwnedMarker(content, "BEGIN reflaxe_elixir live_react_dependency", "END reflaxe_elixir live_react_dependency",
				IntegrationCore.liveReactDependencyLines(), "mix.exs LiveReact dependency");
		} else if (dependencyOwned) {
			removeInsertedDependencyMarker(content, "BEGIN reflaxe_elixir live_react_dependency", "END reflaxe_elixir live_react_dependency",
				IntegrationCore.liveReactDependencyLines(), "mix.exs LiveReact dependency");
		} else content;

		updated = restoreOwnedMarker(updated, "BEGIN reflaxe_elixir live_react_assets_setup", "END reflaxe_elixir live_react_assets_setup",
			desiredAssetAliasLines("assets.setup", IntegrationCore.packageCommand(topology.packageRootRelative, "npm install --no-audit --no-fund"),
				mapGetNullableString(restores, "mix.assets.setup")),
			mapGetTerm(restores, "mix.assets.setup"), "mix.exs assets.setup");
		updated = restoreOwnedMarker(updated, "BEGIN reflaxe_elixir live_react_assets_build", "END reflaxe_elixir live_react_assets_build",
			desiredAssetAliasLines("assets.build", IntegrationCore.packageCommand(topology.packageRootRelative, "npm run assets:build"),
				mapGetNullableString(restores, "mix.assets.build")),
			mapGetTerm(restores, "mix.assets.build"), "mix.exs assets.build");
		return restoreOwnedMarker(updated, "BEGIN reflaxe_elixir live_react_assets_deploy", "END reflaxe_elixir live_react_assets_deploy",
			desiredAssetAliasLines("assets.deploy", IntegrationCore.packageCommand(topology.packageRootRelative, "npm run assets:build"),
				mapGetNullableString(restores, "mix.assets.deploy")),
			mapGetTerm(restores, "mix.assets.deploy"), "mix.exs assets.deploy");
	}

	public static function removeConfigWiring(content:String, restores:Term):String {
		return removeAppendedOwnedMarker(content, "BEGIN reflaxe_elixir live_react_config", "END reflaxe_elixir live_react_config",
			IntegrationCore.liveReactConfigLines(), mapGetTerm(restores, "config.trailingWhitespace"), "config/config.exs LiveReact config");
	}

	public static function removeDevWiring(content:String, topology:LiveReactTopology, restores:Term):String {
		var watcher = markerInnerLines(content, "BEGIN reflaxe_elixir live_react_vite_watcher", "END reflaxe_elixir live_react_vite_watcher",
			"config/dev.exs Vite watcher");
		if (!sameArray(watcher, [IntegrationCore.viteWatcherLine(topology.packageRootRelative)]))
			return Kernel.raiseValue("config/dev.exs LiveReact Vite watcher drifted. No writes occurred.");
		var updated = restoreOwnedMarker(content, "BEGIN reflaxe_elixir live_react_vite_watcher", "END reflaxe_elixir live_react_vite_watcher", watcher,
			mapGetTerm(restores, "dev.esbuildWatcher"), "config/dev.exs Vite watcher");
		return removeAppendedOwnedMarker(updated, "BEGIN reflaxe_elixir live_react_vite_host", "END reflaxe_elixir live_react_vite_host",
			IntegrationCore.liveReactDevConfigLines(), mapGetTerm(restores, "dev.trailingWhitespace"), "config/dev.exs LiveReact host");
	}

	public static function removeAppJsWiring(content:String, restores:Term):String {
		var updated = restoreOwnedMarker(content, "BEGIN reflaxe_elixir live_react_import", "END reflaxe_elixir live_react_import",
			IntegrationCore.liveReactImportLines(), null, "assets/js/app.js LiveReact import");
		var declared = markerPresence(updated, "BEGIN reflaxe_elixir live_react_hooks", "END reflaxe_elixir live_react_hooks");
		var window = markerPresence(updated, "BEGIN reflaxe_elixir live_react_window_hooks", "END reflaxe_elixir live_react_window_hooks");
		if (declared == PRESENT && window == MISSING)
			return restoreOwnedMarker(updated, "BEGIN reflaxe_elixir live_react_hooks", "END reflaxe_elixir live_react_hooks",
				IntegrationCore.declaredHooksLines(), null, "assets/js/app.js declared hooks");
		if (declared == MISSING && window == PRESENT) {
			updated = restoreOwnedMarker(updated, "BEGIN reflaxe_elixir live_react_window_hooks", "END reflaxe_elixir live_react_window_hooks",
				IntegrationCore.windowHooksLines(), null, "assets/js/app.js window hooks");
			return removeHooksProperty(updated, restores);
		}
		return Kernel.raiseValue("assets/js/app.js must contain exactly one owned LiveReact hook strategy. No writes occurred.");
	}

	public static function removeRootLayoutWiring(content:String, restores:Term):String {
		var original:Null<String> = ElixirMap.getTyped(restores, "layout.appScript");
		if (original == null)
			return Kernel.raiseValue(IntegrationCore.MANIFEST_FILENAME + " is missing the original root-layout script. No writes occurred.");
		return restoreOwnedMarker(content, "BEGIN reflaxe_elixir live_react_vite_assets", "END reflaxe_elixir live_react_vite_assets",
			rootAssetInnerLines(original), original, "Phoenix root layout LiveReact assets");
	}

	public static function putRestore(restores:Term, key:String, value:Term):Term {
		var fetched = ElixirMap.fetchTerm(restores, key);
		var fetchedTag = tag(fetched);
		if (fetchedTag == ERROR)
			return ElixirMap.putTerm(restores, key, value);
		var existing = Kernel.elem(fetched, 1);
		if (existing == value)
			return restores;
		return Kernel.raiseValue(IntegrationCore.MANIFEST_FILENAME + " restore metadata for " + key + " changed from " + Kernel.inspect(existing) + " to "
			+ Kernel.inspect(value) + ". No writes occurred.");
	}

	public static function requireRestoreKey(restores:Term, key:String):Void {
		if (!ElixirMap.hasKeyTerm(restores, key))
			Kernel.raise(IntegrationCore.MANIFEST_FILENAME + " is missing " + key + " restore metadata. No writes occurred.");
	}

	static function patchLiveReactDependency(content:String, dependency:LiveReactDependency):String {
		var pattern = rx("\\{\\s*:live_react\\b");
		if (!dependency.owned) {
			var occurrences = Regex.scan(pattern, content).length;
			if (occurrences != 1)
				return Kernel.raiseValue("mix.exs must contain exactly one hand-owned :live_react dependency; found "
					+ Kernel.toString(occurrences)
					+ ". No writes occurred.");
			return content;
		}

		var beginToken = "BEGIN reflaxe_elixir live_react_dependency";
		var endToken = "END reflaxe_elixir live_react_dependency";
		var desired = IntegrationCore.liveReactDependencyLines();
		var replaced = ProjectPatch.replaceMarkerBlockLines(content, beginToken, endToken, desired);
		var replacedTag = tag(replaced);
		if (replacedTag == OK)
			return Kernel.elemAs(replaced, 1);
		if (replacedTag == ERROR)
			return Kernel.raiseValue("mix.exs has a malformed LiveReact dependency marker (" + Kernel.inspect(Kernel.elem(replaced, 1))
				+ "). No writes occurred.");
		if (Regex.match(pattern, content))
			return
				Kernel.raiseValue("mix.exs contains an unowned :live_react dependency while the integration manifest says PhoenixHx owns it. No writes occurred.");
		return insertIntoFunctionList(content, rx("\\bdefp?\\s+deps\\b"), markerLines(beginToken, endToken, desired, "      ", "#"), "mix.exs deps()");
	}

	static function patchAssetAlias(content:String, aliasName:String, desiredLine:String, beginToken:String, endToken:String, restoreKey:String,
			restores:Term):{
		_0:String,
		_1:Term
	} {
		var desired = desiredAssetAliasLines(aliasName, desiredLine, mapGetNullableString(restores, restoreKey));
		var replaced = ProjectPatch.replaceMarkerBlockLines(content, beginToken, endToken, desired);
		var replacedTag = tag(replaced);
		if (replacedTag == OK)
			return {_0: Kernel.elemAs(replaced, 1), _1: restores};
		if (replacedTag == ERROR)
			return Kernel.raiseValue("mix.exs has a malformed " + aliasName + " LiveReact marker (" + Kernel.inspect(Kernel.elem(replaced, 1))
				+ "). No writes occurred.");
		var lines = splitLines(content);
		var span = findAliasSpan(lines, aliasName);
		return span._0 == span._1 ? patchSingleLineAssetAlias(lines, span._0, aliasName, desiredLine, beginToken, endToken, restoreKey,
			restores) : patchMultilineAssetAlias(lines, span._0, span._1, aliasName, desired, beginToken, endToken, restoreKey, restores);
	}

	static function patchSingleLineAssetAlias(lines:Array<String>, index:Int, aliasName:String, desiredLine:String, beginToken:String, endToken:String,
			restoreKey:String, restores:Term):{
		_0:String,
		_1:Term
	} {
		var original = at(lines, index);
		if (findUnownedViteTask(lines, index, index))
			return Kernel.raiseValue("mix.exs "
				+ aliasName
				+ " already contains an unowned Vite task. No writes occurred. Adopt the exact PhoenixHx marker block or use manual integration.");
		var desired = renderSingleLineAssetAlias(original, aliasName, desiredLine);
		var block = markerLines(beginToken, endToken, desired, leadingIndent(original), "#");
		var updated = List.replaceAt(lines, index, Enum.join(block, "\n"));
		return {_0: Enum.join(updated, "\n"), _1: putRestore(restores, restoreKey, original)};
	}

	static function patchMultilineAssetAlias(lines:Array<String>, startIndex:Int, endIndex:Int, aliasName:String, desired:Array<String>, beginToken:String,
			endToken:String, restoreKey:String, restores:Term):{
		_0:String,
		_1:Term
	} {
		var esbuildIndices = indices(startIndex, endIndex + 1, function(index:Int):Bool {
			return Regex.match(rx("^\\s*\"?esbuild(?:\\.install|\\s)"), ElixirString.trimLeading(at(lines, index)));
		});
		if (esbuildIndices.length > 1)
			return Kernel.raiseValue("mix.exs " + aliasName + " contains multiple esbuild tasks. No writes occurred. Manual integration is required.");
		if (esbuildIndices.length == 1) {
			var index = esbuildIndices[0];
			var original = at(lines, index);
			var block = markerLines(beginToken, endToken, desired, leadingIndent(original), "#");
			return {_0: Enum.join(List.replaceAt(lines, index, Enum.join(block, "\n")), "\n"), _1: putRestore(restores, restoreKey, original)};
		}
		if (findUnownedViteTask(lines, startIndex, endIndex))
			return Kernel.raiseValue("mix.exs "
				+ aliasName
				+ " already contains an unowned Vite task. No writes occurred. Adopt the exact PhoenixHx marker block or use manual integration.");
		var insertion = aliasInsertionIndex(lines, startIndex, endIndex);
		var block = markerLines(beginToken, endToken, desired, aliasEntryIndent(lines, startIndex, endIndex), "#");
		return {_0: Enum.join(List.insertAt(lines, insertion, Enum.join(block, "\n")), "\n"), _1: putRestore(restores, restoreKey, null)};
	}

	static function desiredAssetAliasLines(aliasName:String, desiredLine:String, original:Null<String>):Array<String> {
		return original != null
			&& singleLineAlias(original, aliasName) ? renderSingleLineAssetAlias(original, aliasName, desiredLine) : [desiredLine];
	}

	static function singleLineAlias(line:String, aliasName:String):Bool {
		return Regex.match(rx("^[\\s]*[\"']" + Regex.escape(aliasName) + "[\"']\\s*:\\s*\\[.*\\]\\s*,?\\s*$"), line);
	}

	static function renderSingleLineAssetAlias(line:String, aliasName:String, desiredLine:String):Array<String> {
		var indent = leadingIndent(line);
		var unindented = ElixirString.replacePrefix(line, indent, "");
		var pattern = rx("^([\"']" + Regex.escape(aliasName) + "[\"']\\s*:\\s*)\\[(.*)\\](\\s*,?\\s*)$");
		var captures = Regex.run(pattern, unindented);
		if (captures == null || captures.length != 4)
			return Kernel.raiseValue("mix.exs " + aliasName + " is not a supported single-line string-task alias. No writes occurred.");
		var parsed = Code.stringToQuoted("[" + captures[2] + "]");
		var parsedTag = tag(parsed);
		if (parsedTag != OK)
			return Kernel.raiseValue("mix.exs " + aliasName + " is not a supported single-line string-task alias. No writes occurred.");
		var items:Array<Term> = Kernel.elemAs(parsed, 1);
		if (!Enum.all(items, function(item:Term):Bool return Kernel.isBinary(item)))
			return Kernel.raiseValue("mix.exs "
				+ aliasName
				+ " single-line alias must contain literal string tasks. No writes occurred. Expand the alias manually for custom terms.");
		var desired:Term = Code.stringToQuotedBang(ElixirString.trimTrailingWith(desiredLine, ","));
		var esbuildCount = Enum.countBy(items, function(item:Term):Bool return ElixirString.startsWith(Kernel.toString(item), "esbuild"));
		if (esbuildCount > 1)
			return Kernel.raiseValue("mix.exs " + aliasName + " contains multiple esbuild tasks. No writes occurred. Manual integration is required.");
		var updatedItems = esbuildCount == 1 ? Enum.map(items, function(item:Term):Term {
			return ElixirString.startsWith(Kernel.toString(item), "esbuild") ? desired : item;
		}) : Enum.concatTwo([desired], items);
		var rendered = Enum.map(Enum.withIndex(updatedItems), function(entry:Term):String {
			var item = Kernel.elem(entry, 0);
			var index:Int = Kernel.elemAs(entry, 1);
			var suffix = index == updatedItems.length - 1 ? "" : ",";
			return "  " + Kernel.inspect(item) + suffix;
		});
		return Enum.concatTwo(Enum.concatTwo([captures[1] + "["], rendered), ["]" + captures[3]]);
	}

	static function findAliasSpan(lines:Array<String>, aliasName:String):{_0:Int, _1:Int} {
		var startIndex:Null<Int> = null;
		for (entry in Enum.withIndex(lines)) {
			var line:String = Kernel.elemAs(entry, 0);
			var index:Int = Kernel.elemAs(entry, 1);
			if (startIndex == null && Regex.match(rx("[\"']" + Regex.escape(aliasName) + "[\"']\\s*:\\s*\\["), line))
				startIndex = index;
		}
		if (startIndex == null)
			return Kernel.raiseValue("mix.exs has no "
				+ Kernel.inspect(aliasName)
				+ " list alias. No writes occurred. Canonical PhoenixHx aliases are required.");
		var initialDepth = bracketDelta(at(lines, startIndex));
		if (initialDepth < 0)
			return Kernel.raiseValue("mix.exs " + aliasName + " is not a recognizable list alias. No writes occurred.");
		if (initialDepth == 0)
			return {_0: startIndex, _1: startIndex};
		return findAliasEnd(lines, aliasName, startIndex, initialDepth);
	}

	static function findAliasEnd(lines:Array<String>, aliasName:String, startIndex:Int, initialDepth:Int):{_0:Int, _1:Int} {
		var depth = initialDepth;
		var endIndex:Null<Int> = null;
		for (index in (startIndex + 1)...lines.length) {
			if (endIndex == null) {
				depth += bracketDelta(at(lines, index));
				if (depth == 0)
					endIndex = index;
			}
		}
		if (endIndex == null)
			return Kernel.raiseValue("mix.exs " + aliasName + " list is not balanced. No writes occurred.");
		return {_0: startIndex, _1: endIndex};
	}

	static function bracketDelta(line:String):Int {
		return Enum.reduce(ElixirString.graphemes(line), 0, function(character:String, depth:Int):Int {
			return character == "[" ? depth + 1 : character == "]" ? depth - 1 : depth;
		});
	}

	static function findUnownedViteTask(lines:Array<String>, startIndex:Int, endIndex:Int):Bool {
		for (index in startIndex...(endIndex + 1)) {
			var line = at(lines, index);
			if (ElixirString.contains(line, "npm run assets:build") || ElixirString.contains(line, "npm install"))
				return true;
		}
		return false;
	}

	static function aliasInsertionIndex(lines:Array<String>, startIndex:Int, endIndex:Int):Int {
		for (index in (startIndex + 1)...endIndex)
			if (ElixirString.contains(at(lines, index), "END reflaxe_elixir haxe_compile_client_alias"))
				return index + 1;
		return startIndex + 1;
	}

	static function aliasEntryIndent(lines:Array<String>, startIndex:Int, endIndex:Int):String {
		for (index in (startIndex + 1)...endIndex) {
			var line = at(lines, index);
			if (ElixirString.trim(line) != "")
				return leadingIndent(line);
		}
		return "        ";
	}

	static function insertIntoFunctionList(content:String, functionPattern:Term, blockLines:Array<String>, label:String):String {
		var options:KeywordList<Term> = [{_0: RETURN, _1: INDEX}];
		var match = Regex.runWithKeywordOptions(functionPattern, content, options);
		if (match == null || !Kernel.isList(match))
			return Kernel.raiseValue("could not find " + label + ". No writes occurred.");
		var matches:Array<Term> = match;
		if (matches.length == 0)
			return Kernel.raiseValue("could not find " + label + ". No writes occurred.");
		var first:Term = matches[0];
		var functionPosition:Int = Kernel.elemAs(first, 0);
		var remainder = ElixirString.slice(content, functionPosition, Kernel.byteSize(content) - functionPosition);
		var listMatch = ErlangBinary.match(remainder, "[");
		if (listMatch == NOMATCH)
			return Kernel.raiseValue("could not find the list in " + label + ". No writes occurred.");
		var matchPosition:Int = Kernel.elemAs(listMatch, 0);
		var insertion = functionPosition + matchPosition + 1;
		return ElixirString.slice(content, 0, insertion)
			+ "\n"
			+ Enum.join(blockLines, "\n")
			+ "\n"
			+ ElixirString.slice(content, insertion, Kernel.byteSize(content) - insertion);
	}

	static function insertViteWatcher(content:String, watcherLine:String, restores:Term):{_0:String, _1:Term} {
		if (Regex.match(rxWithOptions("^\\s*vite:\\s*", "m"), content))
			return Kernel.raiseValue("config/dev.exs already contains an unowned Vite watcher. No writes occurred. Manual integration is required.");
		var lines = splitLines(content);
		var esbuild:Array<Term> = [];
		for (entry in Enum.withIndex(lines)) {
			var line:String = Kernel.elemAs(entry, 0);
			if (Regex.match(rx("^\\s*esbuild:\\s*"), line))
				esbuild.push(entry);
		}
		var beginToken = "BEGIN reflaxe_elixir live_react_vite_watcher";
		var endToken = "END reflaxe_elixir live_react_vite_watcher";
		if (esbuild.length == 1) {
			var original:String = Kernel.elemAs(esbuild[0], 0);
			var index:Int = Kernel.elemAs(esbuild[0], 1);
			if (!balancedSingleLineExpression(original))
				return Kernel.raiseValue("config/dev.exs has a multi-line or ambiguous esbuild watcher. No writes occurred. Manual integration is required.");
			var block = markerLines(beginToken, endToken, [watcherLine], leadingIndent(original), "#");
			return {_0: Enum.join(List.replaceAt(lines, index, Enum.join(block, "\n")), "\n"), _1: putRestore(restores, "dev.esbuildWatcher", original)};
		}
		if (esbuild.length == 0) {
			var insertion = watcherListInsertionIndex(lines);
			var block = markerLines(beginToken, endToken, [watcherLine], watcherEntryIndent(lines, insertion), "#");
			return {_0: Enum.join(List.insertAt(lines, insertion, Enum.join(block, "\n")), "\n"), _1: putRestore(restores, "dev.esbuildWatcher", null)};
		}
		return Kernel.raiseValue("config/dev.exs contains "
			+ Kernel.toString(esbuild.length)
			+ " esbuild watcher entries. No writes occurred. Manual integration is required.");
	}

	static function balancedSingleLineExpression(line:String):Bool {
		return occurrenceCount(line, "{") == occurrenceCount(line, "}")
			&& occurrenceCount(line, "[") == occurrenceCount(line, "]")
			&& occurrenceCount(line, "(") == occurrenceCount(line, ")");
	}

	static function occurrenceCount(content:String, token:String):Int {
		return ErlangBinary.matches(content, token).length;
	}

	static function watcherListInsertionIndex(lines:Array<String>):Int {
		var watcherIndex:Null<Int> = null;
		for (entry in Enum.withIndex(lines)) {
			var line:String = Kernel.elemAs(entry, 0);
			if (watcherIndex == null && Regex.match(rx("\\bwatchers\\s*:"), line))
				watcherIndex = Kernel.elemAs(entry, 1);
		}
		if (watcherIndex == null)
			return Kernel.raiseValue("config/dev.exs has no watchers configuration. No writes occurred. Canonical Phoenix watcher topology is required.");
		var end = Kernel.minInt(lines.length - 1, watcherIndex + 16);
		for (index in watcherIndex...(end + 1))
			if (ElixirString.contains(at(lines, index), "["))
				return index + 1;
		return Kernel.raiseValue("config/dev.exs watchers configuration has no recognizable list. No writes occurred.");
	}

	static function watcherEntryIndent(lines:Array<String>, insertionIndex:Int):String {
		var end = Kernel.minInt(lines.length - 1, insertionIndex + 11);
		for (index in insertionIndex...(end + 1)) {
			var line = at(lines, index);
			var trimmed = ElixirString.trim(line);
			if (trimmed != "" && trimmed != "]" && trimmed != "])")
				return leadingIndent(line);
		}
		return "    ";
	}

	static function patchAppJsImport(content:String):String {
		var beginToken = "BEGIN reflaxe_elixir live_react_import";
		var endToken = "END reflaxe_elixir live_react_import";
		var desired = IntegrationCore.liveReactImportLines();
		var replaced = ProjectPatch.replaceMarkerBlockLines(content, beginToken, endToken, desired);
		var replacedTag = tag(replaced);
		if (replacedTag == OK)
			return Kernel.elemAs(replaced, 1);
		if (replacedTag == ERROR)
			return Kernel.raiseValue("assets/js/app.js has a malformed LiveReact import marker ("
				+ Kernel.inspect(Kernel.elem(replaced, 1))
				+ "). No writes occurred.");
		if (ElixirString.contains(content, "live-react-hooks"))
			return Kernel.raiseValue("assets/js/app.js already imports an unowned LiveReact hook module. No writes occurred. Manual integration is required.");
		var lines = splitLines(content);
		var lastImport = -1;
		for (entry in Enum.withIndex(lines)) {
			var line:String = Kernel.elemAs(entry, 0);
			if (ElixirString.startsWith(ElixirString.trimLeading(line), "import "))
				lastImport = Kernel.elemAs(entry, 1);
		}
		return Enum.join(List.insertAt(lines, lastImport + 1, Enum.join(markerLines(beginToken, endToken, desired, "", "//"), "\n")), "\n");
	}

	static function patchAppJsHooks(content:String, restores:Term):{_0:String, _1:Term} {
		var declaration:Null<Int> = null;
		for (entry in Enum.withIndex(splitLines(content))) {
			var line:String = Kernel.elemAs(entry, 0);
			if (declaration == null && Regex.match(rx("^\\s*(?:let|const|var)\\s+Hooks\\b"), line))
				declaration = Kernel.elemAs(entry, 1);
		}
		return declaration == null ? patchWindowHooks(content, restores) : patchDeclaredHooks(content, declaration, restores);
	}

	static function patchDeclaredHooks(content:String, declaration:Int, restores:Term):{_0:String, _1:Term} {
		var beginToken = "BEGIN reflaxe_elixir live_react_hooks";
		var endToken = "END reflaxe_elixir live_react_hooks";
		var desired = IntegrationCore.declaredHooksLines();
		var replaced = ProjectPatch.replaceMarkerBlockLines(content, beginToken, endToken, desired);
		var replacedTag = tag(replaced);
		if (replacedTag == OK)
			return {_0: Kernel.elemAs(replaced, 1), _1: restores};
		if (replacedTag == ERROR)
			return Kernel.raiseValue("assets/js/app.js has a malformed LiveReact hooks marker ("
				+ Kernel.inspect(Kernel.elem(replaced, 1))
				+ "). No writes occurred.");
		var lines = splitLines(content);
		var insertion = declaration + 1;
		var end = Kernel.minInt(lines.length - 1, declaration + 8);
		for (index in (declaration + 1)...(end + 1))
			if (ElixirString.contains(at(lines, index), "END reflaxe_elixir hooks_after_decl"))
				insertion = index + 1;
		var block = markerLines(beginToken, endToken, desired, leadingIndent(at(lines, declaration)), "//");
		return {_0: Enum.join(List.insertAt(lines, insertion, Enum.join(block, "\n")), "\n"), _1: restores};
	}

	static function patchWindowHooks(content:String, restores:Term):{_0:String, _1:Term} {
		var beginToken = "BEGIN reflaxe_elixir live_react_window_hooks";
		var endToken = "END reflaxe_elixir live_react_window_hooks";
		var desired = IntegrationCore.windowHooksLines();
		var replaced = ProjectPatch.replaceMarkerBlockLines(content, beginToken, endToken, desired);
		var replacedTag = tag(replaced);
		var updated:String;
		if (replacedTag == OK) {
			updated = Kernel.elemAs(replaced, 1);
		} else if (replacedTag == ERROR) {
			return Kernel.raiseValue("assets/js/app.js has a malformed LiveReact window-hooks marker ("
				+ Kernel.inspect(Kernel.elem(replaced, 1))
				+ "). No writes occurred.");
		} else {
			var lines = splitLines(content);
			var liveSocket = findLiveSocketIndex(lines);
			var block = markerLines(beginToken, endToken, desired, "", "//");
			updated = Enum.join(List.insertAt(lines, liveSocket, Enum.join(block, "\n")), "\n");
		}
		return liveSocketUsesWindowHooks(updated) ? {_0: updated, _1: restores} : patchLiveSocketHooksProperty(updated, restores);
	}

	static function liveSocketUsesWindowHooks(content:String):Bool {
		return Enum.any(splitLines(content), function(line:String):Bool {
			return ElixirString.contains(line, "hooks:") && ElixirString.contains(line, "window.Hooks");
		});
	}

	static function patchLiveSocketHooksProperty(content:String, restores:Term):{_0:String, _1:Term} {
		var beginToken = "BEGIN reflaxe_elixir live_react_hooks_property";
		var endToken = "END reflaxe_elixir live_react_hooks_property";
		var presence = markerPresence(content, beginToken, endToken);
		var desired = presence == PRESENT ? expectedHooksPropertyLines(restores) : [];
		var replaced = ProjectPatch.replaceMarkerBlockLines(content, beginToken, endToken, desired);
		var replacedTag = tag(replaced);
		if (replacedTag == OK)
			return {_0: Kernel.elemAs(replaced, 1), _1: restores};
		if (replacedTag == ERROR)
			return Kernel.raiseValue("assets/js/app.js has a malformed LiveReact hooks-property marker ("
				+ Kernel.inspect(Kernel.elem(replaced, 1))
				+ "). No writes occurred.");

		var lines = splitLines(content);
		var liveSocket = findLiveSocketIndex(lines);
		var hooksIndices = indices(liveSocket, Kernel.minInt(lines.length - 1, liveSocket + 20) + 1,
			function(index:Int):Bool return Regex.match(rx("^\\s*hooks\\s*:"), at(lines, index)));
		if (hooksIndices.length == 1) {
			var index = hooksIndices[0];
			var original = at(lines, index);
			var block = markerLines(beginToken, endToken, [rewriteHooksPropertyWithWindow(original)], leadingIndent(original), "//");
			return {_0: Enum.join(List.replaceAt(lines, index, Enum.join(block, "\n")), "\n"), _1: putRestore(restores, "app.hooksProperty", original)};
		}
		if (hooksIndices.length > 1)
			return Kernel.raiseValue("assets/js/app.js has "
				+ Kernel.toString(hooksIndices.length)
				+ " LiveSocket hooks properties near construction. No writes occurred.");
		var liveSocketLine = at(lines, liveSocket);
		if (Regex.match(rx("\\bhooks\\s*:"), liveSocketLine))
			return
				Kernel.raiseValue("assets/js/app.js has an inline LiveSocket hooks property that cannot be patched safely. No writes occurred. Expand the options object or use manual integration.");
		if (!ElixirString.contains(liveSocketLine, "{"))
			return Kernel.raiseValue("assets/js/app.js LiveSocket options are not a recognizable object. No writes occurred.");
		var candidateIndent = leadingIndent(atDefault(lines, liveSocket + 1, "  "));
		var nextIndent = candidateIndent == "" ? leadingIndent(liveSocketLine) + "  " : candidateIndent;
		var block = markerLines(beginToken, endToken, ["hooks: window.Hooks || {},"], nextIndent, "//");
		var updated:String;
		if (Regex.match(rx("\\{\\s*\\}"), liveSocketLine)) {
			var options:KeywordList<Term> = [{_0: GLOBAL, _1: false}];
			var replacementText = Enum.join(["{", Enum.join(block, "\n"), leadingIndent(liveSocketLine) + "}"], "\n");
			var replacement = ElixirString.replaceWithKeywordOptions(liveSocketLine, rx("\\{\\s*\\}"), replacementText, options);
			updated = Enum.join(List.replaceAt(lines, liveSocket, replacement), "\n");
		} else {
			updated = Enum.join(List.insertAt(lines, liveSocket + 1, Enum.join(block, "\n")), "\n");
		}
		return {_0: updated, _1: putRestore(restores, "app.hooksProperty", null)};
	}

	static function expectedHooksPropertyLines(restores:Term):Array<String> {
		var fetched = ElixirMap.fetchTerm(restores, "app.hooksProperty");
		var fetchedTag = tag(fetched);
		if (fetchedTag == ERROR)
			return Kernel.raiseValue(IntegrationCore.MANIFEST_FILENAME + " is missing app.hooksProperty restore metadata. No writes occurred.");
		var original:Term = Kernel.elem(fetched, 1);
		return original == null ? ["hooks: window.Hooks || {},"] : [rewriteHooksPropertyWithWindow(Kernel.toString(original))];
	}

	static function findLiveSocketIndex(lines:Array<String>):Int {
		for (entry in Enum.withIndex(lines)) {
			var line:String = Kernel.elemAs(entry, 0);
			if (ElixirString.contains(line, "new LiveSocket"))
				return Kernel.elemAs(entry, 1);
		}
		return Kernel.raiseValue("assets/js/app.js has no recognizable LiveSocket construction. No writes occurred.");
	}

	static function rewriteHooksPropertyWithWindow(line:String):String {
		var trimmed = ElixirString.trim(line);
		var trailingComma = ElixirString.endsWith(trimmed, ",");
		var withoutComma = trailingComma ? ElixirString.trimTrailingWith(trimmed, ",") : trimmed;
		var options:KeywordList<Term> = [{_0: PARTS, _1: 2}];
		var parts = ElixirString.splitWithKeywordOptions(withoutComma, "hooks:", options);
		if (parts.length != 2)
			return Kernel.raiseValue("assets/js/app.js hooks property is not recognizable. No writes occurred.");
		var expression = ElixirString.trim(parts[1]);
		var merged:String;
		if (ElixirString.startsWith(expression, "{") && ElixirString.endsWith(expression, "}")) {
			var inner = ElixirString.trim(ElixirString.trimTrailingWith(ElixirString.trimLeadingWith(expression, "{"), "}"));
			merged = inner == "" ? "{...(window.Hooks || {})}" : "{" + inner + ", ...(window.Hooks || {})}";
		} else if (expression != "") {
			merged = "{..." + expression + ", ...(window.Hooks || {})}";
		} else {
			return Kernel.raiseValue("assets/js/app.js has an empty hooks property. No writes occurred.");
		}
		return "hooks: " + merged + (trailingComma ? "," : "");
	}

	static function findRootAppScript(content:String):RootScript {
		var lines = splitLines(content);
		var starts:Array<Term> = [];
		for (entry in Enum.withIndex(lines)) {
			var line:String = Kernel.elemAs(entry, 0);
			if (ElixirString.contains(line, "<script") && ElixirString.contains(line, "/assets/app.js"))
				starts.push(entry);
		}
		if (starts.length == 0)
			return Kernel.raiseValue("Phoenix root layout has no canonical /assets/app.js script. No writes occurred. Run the Phoenix scaffold first.");
		if (starts.length != 1)
			return Kernel.raiseValue("Phoenix root layout has " + Kernel.toString(starts.length) + " app script candidates. No writes occurred.");
		var line:String = Kernel.elemAs(starts[0], 0);
		var startIndex:Int = Kernel.elemAs(starts[0], 1);
		var endIndex:Null<Int> = ElixirString.contains(line, "</script>") ? startIndex : null;
		if (endIndex == null) {
			var end = Kernel.minInt(lines.length - 1, startIndex + 5);
			for (index in startIndex...(end + 1))
				if (endIndex == null && ElixirString.contains(at(lines, index), "</script>"))
					endIndex = index;
		}
		if (endIndex == null)
			return Kernel.raiseValue("Phoenix root layout app script is not closed within a supported span. No writes occurred.");
		var original = Enum.join(Enum.take(Enum.drop(lines, startIndex), endIndex - startIndex + 1), "\n");
		return {
			original: original,
			startIndex: startIndex,
			endIndex: endIndex,
			indent: leadingIndent(line)
		};
	}

	static function rootAssetInnerLines(original:String):Array<String> {
		if (original == null)
			return Kernel.raiseValue("missing original Phoenix root-layout app script");
		var originalLines = splitLines(original);
		var originalIndent = leadingIndent(originalLines[0]);
		var script = Enum.map(originalLines, function(line:String):String {
			var stripped = ElixirString.startsWith(line,
				originalIndent) ? ElixirString.replacePrefix(line, originalIndent, "") : ElixirString.trimLeading(line);
			return "  " + stripped;
		});
		return Enum.concatTwo(Enum.concatTwo(['<LiveReact.Reload.vite_assets assets={["/js/app.js"]}>'], script), ["</LiveReact.Reload.vite_assets>"]);
	}

	static function removeHooksProperty(content:String, restores:Term):String {
		var presence = markerPresence(content, "BEGIN reflaxe_elixir live_react_hooks_property", "END reflaxe_elixir live_react_hooks_property");
		var fetched = ElixirMap.fetchTerm(restores, "app.hooksProperty");
		var fetchedTag = tag(fetched);
		if (fetchedTag == ERROR && presence == MISSING)
			return content;
		if (fetchedTag == OK && presence == PRESENT)
			return restoreOwnedMarker(content, "BEGIN reflaxe_elixir live_react_hooks_property", "END reflaxe_elixir live_react_hooks_property",
				expectedHooksPropertyLines(restores), Kernel.elem(fetched, 1), "assets/js/app.js hooks property");
		if (fetchedTag == ERROR)
			return Kernel.raiseValue(IntegrationCore.MANIFEST_FILENAME + " is missing app.hooksProperty restore metadata. No writes occurred.");
		return Kernel.raiseValue("assets/js/app.js owned hooks-property marker is missing. No writes occurred.");
	}

	static function removeAppendedOwnedMarker(content:String, beginToken:String, endToken:String, expected:Array<String>, trailing:Term, label:String):String {
		if (!Kernel.isBinary(trailing))
			return Kernel.raiseValue(IntegrationCore.MANIFEST_FILENAME + " is missing trailing-whitespace restore metadata for " + label
				+ ". No writes occurred.");
		var lines = splitLines(content);
		var marker = markerIndices(lines, beginToken, endToken, label);
		var prefix = Enum.take(lines, marker._0);
		var suffix = Enum.drop(lines, marker._1 + 1);
		if (List.last(prefix) != "")
			return Kernel.raiseValue(label + " lost its owned separator line. No writes occurred.");
		restoreOwnedMarker(content, beginToken, endToken, expected, null, label);
		var base = Enum.join(Enum.take(prefix, prefix.length - 1), "\n") + Kernel.toString(trailing);
		return Enum.all(suffix, function(line:String):Bool return ElixirString.trim(line) == "") ? base : base + "\n" + Enum.join(suffix, "\n");
	}

	static function unwrapOwnedMarker(content:String, beginToken:String, endToken:String, expected:Array<String>, label:String):String {
		var lines = splitLines(content);
		var marker = markerIndices(lines, beginToken, endToken, label);
		var indent = leadingIndent(at(lines, marker._0));
		var inner = Enum.take(Enum.drop(lines, marker._0 + 1), marker._1 - marker._0 - 1);
		var actual = Enum.map(inner, function(line:String):String return stripExpectedIndent(line, indent));
		if (!sameArray(actual, expected))
			return Kernel.raiseValue(label + " content drifted inside its ownership markers. No writes occurred.");
		return Enum.join(replaceLineRangeWithLines(lines, marker._0, marker._1, inner), "\n");
	}

	static function removeInsertedDependencyMarker(content:String, beginToken:String, endToken:String, expected:Array<String>, label:String):String {
		var block = Enum.join(markerLines(beginToken, endToken, expected, "      ", "#"), "\n");
		var inserted = "\n" + block + "\n";
		var matches = ErlangBinary.matches(content, inserted);
		if (matches.length != 1)
			return Kernel.raiseValue(label
				+
				" no longer matches the exact inserted dependency block. No writes occurred. Restore the owned block or retain the dependency as hand-owned before retrying.");
		var position:Int = Kernel.elemAs(matches[0], 0);
		var length:Int = Kernel.elemAs(matches[0], 1);
		return Kernel.binaryPart(content, 0, position) + Kernel.binaryPart(content, position + length, Kernel.byteSize(content) - position - length);
	}

	static function restoreOwnedMarker(content:String, beginToken:String, endToken:String, expected:Array<String>, original:Term, label:String):String {
		var lines = splitLines(content);
		var marker = markerIndices(lines, beginToken, endToken, label);
		var indent = leadingIndent(at(lines, marker._0));
		var actual = Enum.map(Enum.take(Enum.drop(lines, marker._0 + 1), marker._1 - marker._0 - 1),
			function(line:String):String return stripExpectedIndent(line, indent));
		if (!sameArray(actual, expected))
			return Kernel.raiseValue(label + " content drifted inside its ownership markers. No writes occurred.");
		var replacement:Array<String> = original == null ? [] : splitLines(Kernel.toString(original));
		return Enum.join(replaceLineRangeWithLines(lines, marker._0, marker._1, replacement), "\n");
	}

	static function stripExpectedIndent(line:String, indent:String):String {
		return indent != "" && ElixirString.startsWith(line, indent) ? ElixirString.replacePrefix(line, indent, "") : line;
	}

	static function markerInnerLines(content:String, beginToken:String, endToken:String, label:String):Array<String> {
		var lines = splitLines(content);
		var marker = markerIndices(lines, beginToken, endToken, label);
		return Enum.map(Enum.take(Enum.drop(lines, marker._0 + 1), marker._1 - marker._0 - 1),
			function(line:String):String return ElixirString.trimLeading(line));
	}

	static function markerIndices(lines:Array<String>, beginToken:String, endToken:String, label:String):{_0:Int, _1:Int} {
		var begins = matchingIndices(lines, beginToken);
		var ends = matchingIndices(lines, endToken);
		if (begins.length == 1 && ends.length == 1 && begins[0] < ends[0])
			return {_0: begins[0], _1: ends[0]};
		return Kernel.raiseValue(label + " must contain exactly one ordered marker pair. No writes occurred.");
	}

	static function markerPresence(content:String, beginToken:String, endToken:String):Atom {
		var lines = splitLines(content);
		var begins = matchingIndices(lines, beginToken);
		var ends = matchingIndices(lines, endToken);
		if (begins.length == 0 && ends.length == 0)
			return MISSING;
		if (begins.length == 1 && ends.length == 1)
			return PRESENT;
		return Kernel.raiseValue("malformed ownership markers for " + beginToken + ". No writes occurred.");
	}

	static function matchingIndices(lines:Array<String>, token:String):Array<Int> {
		var pattern = rx("(?:^|\\s)" + Regex.escape(token) + "(?=$|\\s)");
		var result:Array<Int> = [];
		for (entry in Enum.withIndex(lines)) {
			var line:String = Kernel.elemAs(entry, 0);
			if (Regex.match(pattern, line))
				result.push(Kernel.elemAs(entry, 1));
		}
		return result;
	}

	static function validateFileMarkers(content:String, sourcePath:String, label:String):Void {
		var pairs:Array<{_0:String, _1:String}> = [];
		for (spec in markerSpecs()) {
			var specPath:String = Kernel.elemAs(spec, 0);
			if (specPath == sourcePath)
				pairs.push({_0: Kernel.elemAs(spec, 1), _1: Kernel.elemAs(spec, 2)});
		}
		validateMarkerPairs(content, pairs, label);
	}

	static function validateMarkerPairs(content:String, pairs:Array<{_0:String, _1:String}>, label:String):Void {
		var validated = ProjectPatch.validateMarkerPairs(content, pairs);
		if (validated != OK)
			Kernel.raise(label
				+ " has malformed or overlapping ownership markers: "
				+ Kernel.inspect(Kernel.elem(validated, 1))
				+ ". No writes occurred.");
	}

	static function appendMarkerBlock(content:String, beginToken:String, endToken:String, desired:Array<String>, indent:String, commentPrefix:String):String {
		return ElixirString.trimTrailing(content)
			+ "\n\n"
			+ Enum.join(markerLines(beginToken, endToken, desired, indent, commentPrefix), "\n")
			+ "\n";
	}

	static function markerLines(beginToken:String, endToken:String, desired:Array<String>, indent:String, commentPrefix:String):Array<String> {
		return markerLinesWithSuffix(beginToken, endToken, desired, indent, commentPrefix, "");
	}

	static function markerLinesWithSuffix(beginToken:String, endToken:String, desired:Array<String>, indent:String, commentPrefix:String,
			suffix:String):Array<String> {
		var opening = indent + commentPrefix + " " + beginToken + (commentPrefix == "<%!--" ? " --%>" : suffix);
		var closing = indent + commentPrefix + " " + endToken + (commentPrefix == "<%!--" ? " --%>" : suffix);
		var body = Enum.map(desired, function(line:String):String return indent + line);
		return Enum.concatTwo(Enum.concatTwo([opening], body), [closing]);
	}

	static function replaceLineRange(lines:Array<String>, startIndex:Int, endIndex:Int, replacement:String):Array<String> {
		return Enum.concatTwo(Enum.concatTwo(Enum.take(lines, startIndex), [replacement]), Enum.drop(lines, endIndex + 1));
	}

	static function replaceLineRangeWithLines(lines:Array<String>, startIndex:Int, endIndex:Int, replacements:Array<String>):Array<String> {
		return Enum.concatTwo(Enum.concatTwo(Enum.take(lines, startIndex), replacements), Enum.drop(lines, endIndex + 1));
	}

	static function trailingWhitespace(content:String):String {
		var trimmed = ElixirString.trimTrailing(content);
		return Kernel.binaryPart(content, Kernel.byteSize(trimmed), Kernel.byteSize(content) - Kernel.byteSize(trimmed));
	}

	static function leadingIndent(line:String):String {
		var capture = Regex.run(rx("^\\s*"), line);
		return capture == null || capture.length == 0 ? "" : capture[0];
	}

	static function splitLines(content:String):Array<String> {
		var options:KeywordList<Term> = [{_0: TRIM, _1: false}];
		return ElixirString.splitWithKeywordOptions(content, "\n", options);
	}

	static function at(lines:Array<String>, index:Int):String {
		return Enum.at(lines, index, "");
	}

	static function atDefault(lines:Array<String>, index:Int, fallback:String):String {
		return Enum.at(lines, index, fallback);
	}

	static function indices(start:Int, endExclusive:Int, predicate:Int->Bool):Array<Int> {
		var result:Array<Int> = [];
		for (index in start...endExclusive)
			if (predicate(index))
				result.push(index);
		return result;
	}

	static function sameArray(left:Array<String>, right:Array<String>):Bool {
		return left == right;
	}

	static function mapGet<T>(map:Term, key:String):T {
		return ElixirMap.getTyped(map, key);
	}

	static function mapGetTerm(map:Term, key:String):Term {
		return ElixirMap.getTyped(map, key);
	}

	static function mapGetNullableString(map:Term, key:String):Null<String> {
		return ElixirMap.getTyped(map, key);
	}

	static function tag(value:Term):Atom {
		return Kernel.isTuple(value) ? Kernel.elemAs(value, 0) : value;
	}

	static function rx(pattern:String):Term {
		return Regex.compileBang(pattern);
	}

	static function rxWithOptions(pattern:String, options:String):Term {
		return Regex.compileBangWithOptions(pattern, options);
	}
}
