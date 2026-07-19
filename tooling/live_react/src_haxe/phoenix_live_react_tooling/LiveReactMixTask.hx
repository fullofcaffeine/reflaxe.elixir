package phoenix_live_react_tooling;

import elixir.ElixirMap;
import elixir.Enum;
import elixir.File;
import elixir.Keyword;
import elixir.Kernel;
import elixir.OptionParser;
import elixir.OptionParser.OptionSwitch;
import elixir.mix.Mix;
import elixir.mix.Project;
import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.Term;

/**
 * Installs, verifies, or removes the opt-in stock LiveReact/Vite integration.
 *
 * PhoenixHx owns project wiring and generated ownership metadata. Stock
 * `live_react` remains the server/browser runtime.
 *
 *     mix haxe.phoenix.live_react
 *     mix haxe.phoenix.live_react --check
 *     mix haxe.phoenix.live_react --remove
 *
 * ## Options
 *
 *   * `--check` - compare the complete desired integration without writing or fetching
 *   * `--remove` - remove only signature/marker/key-owned integration state
 *   * `--yes` - do not prompt before apply or remove
 *   * `--warn-only` - retain advisory warnings; never bypass ownership or identity failures
 *   * `--package-root PATH` - select the tested `.` or `assets` npm package root
 *
 * The initial integration is client-only. SSR, slots, uploads, streams, and
 * request-selected component modules are intentionally unsupported.
 */
@:keep
@:native("Mix.Tasks.Haxe.Phoenix.LiveReact")
@:mixTask({
	shortdoc: "Sets up/checks/removes stock LiveReact + Vite",
	requirements: ["app.config"]
})
class LiveReactMixTask {
	static inline final APPLY:Atom = "apply";
	static inline final CHECK:Atom = "check";
	static inline final REMOVE:Atom = "remove";
	static inline final CANCELLED:Atom = "cancelled";

	public static function run(args:Array<String>):Term {
		var parsed = OptionParser.parse(args, parserOptions());
		var options = parsed._0;
		var argv = parsed._1;
		var invalid = parsed._2;

		rejectInvalidArguments(argv, invalid);
		rejectUnsupportedOptions(options);

		var mode = parseMode(options);
		var root = File.cwdBang();
		var projectConfig = Project.config();
		var appName:Term = Keyword.get(projectConfig, "app", null);
		var mixDependencies:Array<Term> = Keyword.get(projectConfig, "deps", []);
		var packageRoot:Null<String> = Keyword.get(options, "package_root", null);
		var confirmed = Keyword.get(options, "yes", false) || mode == CHECK;
		var warnOnly = Keyword.get(options, "warn_only", false);
		var confirm:String->Bool = function(message:String):Bool return Mix.shell().yes(message);
		var report:String->Void = function(message:String):Void Mix.shell().info(message);

		var common:KeywordList<Term> = [
			{_0: "app_name", _1: appName == null ? null : Kernel.toString(appName)},
			{_0: "package_root", _1: packageRoot},
			{_0: "mix_dependencies", _1: mixDependencies},
			{_0: "yes", _1: confirmed},
			{_0: "warn_only", _1: warnOnly},
			{_0: "confirm", _1: confirm},
			{_0: "report", _1: report}
		];

		var result = if (mode == APPLY) {
			LiveReactLifecycle.applyBang(root, common);
		} else if (mode == CHECK) {
			LiveReactLifecycle.checkBang(root, common);
		} else {
			LiveReactLifecycle.removeBang(root, common);
		};

		reportResult(mode, result);
		return result;
	}

	static function parserOptions():KeywordList<Term> {
		var switches:Array<OptionSwitch> = [
			{_0: "check", _1: "boolean"},
			{_0: "remove", _1: "boolean"},
			{_0: "yes", _1: "boolean"},
			{_0: "warn_only", _1: "boolean"},
			{_0: "package_root", _1: "string"},
			{_0: "ssr", _1: "boolean"}
		];
		return [{_0: "strict", _1: switches}];
	}

	static function parseMode(options:KeywordList<Term>):Atom {
		var check = Keyword.get(options, "check", false);
		var remove = Keyword.get(options, "remove", false);

		if (check && remove)
			return Kernel.raiseValue("--check and --remove are mutually exclusive");
		if (check)
			return CHECK;
		if (remove)
			return REMOVE;
		return APPLY;
	}

	static function rejectInvalidArguments(argv:Array<String>, invalid:Array<elixir.OptionParser.InvalidOption>):Void {
		if (argv.length == 0 && invalid.length == 0)
			return;

		var details = argv.length == 0 ? "" : "unexpected arguments: " + Enum.join(argv, " ");
		if (invalid.length != 0) {
			if (details != "")
				details += "; ";
			details += "invalid options: " + Kernel.inspect(invalid);
		}

		Kernel.raise('invalid haxe.phoenix.live_react invocation ($details)');
	}

	static function rejectUnsupportedOptions(options:KeywordList<Term>):Void {
		if (Keyword.get(options, "ssr", false)) {
			Kernel.raise("--ssr is not supported by the initial PhoenixHx LiveReact integration. No writes occurred. Client-only setup always emits ssr=false.");
		}
	}

	static function reportResult(mode:Atom, result:Term):Void {
		if (result == CANCELLED) {
			Mix.shell().info("PhoenixHx LiveReact changes cancelled; no writes occurred.");
		} else {
			reportCompletedResult(mode, result);
		}
	}

	static function reportCompletedResult(mode:Atom, result:Term):Void {
		if (mode == APPLY) {
			var packageRoot = topLevelString(result, "package_root");
			Mix.shell().info("PhoenixHx LiveReact integration is current (experimental, client-only).");
			Mix.shell().info("Stock LiveReact identity: " + identityLabel(topLevelValue(result, "dependency")));
			Mix.shell().info("npm package root: " + packageRoot);
			Mix.shell().info("Next: npm install" + packageSuffix(packageRoot));
			Mix.shell().info("Then verify: mix haxe.phoenix.live_react --check");
		} else if (mode == CHECK) {
			Mix.shell().info("PhoenixHx LiveReact check passed; no writes occurred.");
			Mix.shell().info("Stock LiveReact identity: " + identityLabel(topLevelValue(result, "dependency")));
		} else {
			Mix.shell().info("Removed all currently owned PhoenixHx LiveReact state.");
			var retainedKeys:Array<String> = Enum.toList(topLevelValue(result, "retained_package_keys"));
			if (retainedKeys.length != 0) {
				Mix.shell().info("Retained package keys used by hand-owned browser source: " + Enum.join(retainedKeys, ", "));
			}
			if (topLevelValue(result, "retained_live_react_dependency") == true) {
				Mix.shell().info("Retained the stock :live_react Mix dependency and lock entry because hand-owned browser source still imports live_react.");
			}
			Mix.shell().info("Run npm install" + packageSuffix(topLevelString(result, "package_root")) + " to converge the npm lockfile.");
		}
	}

	static function identityLabel(identity:Term):String {
		var sourceKind = stringKeyString(identity, "sourceKind");
		if (sourceKind == "git")
			return stringKeyString(identity, "repository") + "@" + stringKeyString(identity, "resolvedRevision");
		if (sourceKind == "hex")
			return "hex:" + stringKeyString(identity, "package") + "@" + stringKeyString(identity, "resolvedVersion");
		if (sourceKind == "path")
			return "path:" + stringKeyString(identity, "path") + "@" + stringKeyString(identity, "packageVersion");
		return Kernel.raiseValue("unsupported LiveReact dependency identity returned by HaxePhoenixLiveReact");
	}

	static function topLevelString(result:Term, key:Atom):String {
		return Kernel.toString(topLevelValue(result, key));
	}

	static function topLevelValue(result:Term, key:Atom):Term {
		return ElixirMap.get(result, key);
	}

	static function stringKeyString(result:Term, key:String):String {
		return Kernel.toString(ElixirMap.get(result, key));
	}

	static function packageSuffix(path:String):String {
		return path == "." ? "" : " --prefix " + path;
	}
}
