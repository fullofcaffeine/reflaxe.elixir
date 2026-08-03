package phoenix_live_react_tooling;

import elixir.ElixirMap;
import elixir.Enum;
import elixir.File;
import elixir.Keyword;
import elixir.Kernel;
import elixir.OptionParser;
import elixir.OptionParser.OptionSwitch;
import elixir.OptionParser.OptionSwitchTypes;
import elixir.mix.Mix;
import elixir.mix.Project;
import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.Term;

/**
 * Registers one statically named React component and can create application-owned
 * starter source for it.
 *
 *     mix haxe.gen.live_react PreferenceStudio
 *     mix haxe.gen.live_react PreferenceStudio --existing
 *     mix haxe.gen.live_react PreferenceStudio --existing --module ./preference-studio-boundary --export PreferenceStudioBoundary
 *     mix haxe.gen.live_react PreferenceStudio --remove
 *     mix haxe.gen.live_react PreferenceStudio --package-root assets
 *
 * The default creates one strict Haxe wrapper, one trusted TSX boundary, and
 * one inner TSX component. Those files become application-owned immediately;
 * reruns and removal never rewrite or delete them.
 *
 * ## Options
 *
 *   * `--existing` - register compatible source the application already owns
 *   * `--module PATH` - import this existing browser module; requires `--existing`
 *   * `--export NAME` - use this export from the existing module; requires `--existing`
 *   * `--remove` - remove the registry entry but keep application source files
 *   * `--package-root PATH` - select the tested `.` or `assets` npm package root
 *   * `--yes` - do not prompt before a reviewed add or removal
 */
@:keep
@:native("Mix.Tasks.Haxe.Gen.LiveReact")
@:mixTask({
	shortdoc: "Registers a typed stock LiveReact island",
	requirements: ["app.config"]
})
class LiveReactComponentMixTask {
	static inline final CANCELLED:Atom = "cancelled";
	static inline final ADD_COMPONENT:Atom = "add_component";
	static inline final REMOVE_COMPONENT:Atom = "remove_component";
	static inline final MODE:Atom = "mode";
	static inline final NAME:Atom = "name";
	static inline final CREATED_FILES:Atom = "created_files";
	static inline final RETAINED_FILES:Atom = "retained_files";

	public static function run(args:Array<String>):Term {
		var parsed = OptionParser.parse(args, parserOptions());
		var options = parsed.options;
		var argv = parsed.argv;
		var invalid = parsed.invalid;
		if (invalid.length != 0)
			Kernel.raiseValue("invalid haxe.gen.live_react options: " + Kernel.inspect(invalid));
		if (argv.length != 1)
			Kernel.raiseValue("expected one static PascalCase component name. Usage: mix haxe.gen.live_react PreferenceStudio [--existing|--remove]");

		var remove = Keyword.get(options, "remove", false);
		var useExisting = Keyword.get(options, "existing", false);
		var modulePath:Null<String> = Keyword.get(options, "module", null);
		var exportName:Null<String> = Keyword.get(options, "export", null);
		var packageRoot:Null<String> = Keyword.get(options, "package_root", null);
		if (remove && (useExisting || modulePath != null || exportName != null))
			Kernel.raiseValue("--remove cannot be combined with --existing, --module, or --export. No writes occurred.");
		if (!remove && !useExisting && (modulePath != null || exportName != null))
			Kernel.raiseValue("--module and --export adopt application-owned source and therefore require --existing. No writes occurred.");

		var projectConfig = Project.config();
		var appName = Kernel.toString(Keyword.get(projectConfig, "app", null));
		var confirmed = Keyword.get(options, "yes", false);
		var confirm:String->Bool = function(message:String):Bool return Mix.shell().yes(message);
		var report:String->Void = function(message:String):Void Mix.shell().info(message);
		var common:KeywordList<Term> = [
			Keyword.entry("app_name", appName),
			Keyword.entry("module_path", modulePath),
			Keyword.entry("export_name", exportName),
			Keyword.entry("package_root", packageRoot),
			Keyword.entry("existing", useExisting),
			Keyword.entry("yes", confirmed),
			Keyword.entry("confirm", confirm),
			Keyword.entry("report", report)
		];
		var result = remove ? LiveReactLifecycle.removeComponentBang(File.cwdBang(), argv[0],
			common) : LiveReactLifecycle.addComponentBang(File.cwdBang(), argv[0], common);
		reportResult(result);
		return result;
	}

	static function parserOptions():KeywordList<Term> {
		var switches:Array<OptionSwitch> = [
			Keyword.entry("remove", OptionSwitchTypes.BOOLEAN),
			Keyword.entry("existing", OptionSwitchTypes.BOOLEAN),
			Keyword.entry("module", OptionSwitchTypes.STRING),
			Keyword.entry("export", OptionSwitchTypes.STRING),
			Keyword.entry("package_root", OptionSwitchTypes.STRING),
			Keyword.entry("yes", OptionSwitchTypes.BOOLEAN)
		];
		return [Keyword.entry("strict", switches)];
	}

	static function reportResult(result:Term):Void {
		if (result == CANCELLED) {
			Mix.shell().info("LiveReact component changes cancelled; no writes occurred.");
			return;
		}
		var mode:Atom = ElixirMap.get(result, MODE);
		var name = Kernel.toString(ElixirMap.get(result, NAME));
		var created:Array<String> = ElixirMap.get(result, CREATED_FILES);
		var retained:Array<String> = ElixirMap.get(result, RETAINED_FILES);
		if (mode == ADD_COMPONENT) {
			Mix.shell().info("LiveReact component " + name + " is registered in the static registry.");
			if (created.length != 0)
				Mix.shell()
					.info("Created application-owned starter source:\n" + Enum.mapJoin(created, "\n", function(path:String):String return "  * " + path));
			else
				Mix.shell().info("No starter source was changed; existing application source remains application-owned.");
			Mix.shell()
				.info("Next: review the closed Haxe assigns and trusted TypeScript boundary, add a Live Event Protocol adapter for client pushes, then compile Haxe and run the Vite type/build checks.");
		} else if (mode == REMOVE_COMPONENT) {
			Mix.shell().info("Removed " + name + " from the static LiveReact registry.");
			if (retained.length != 0)
				Mix.shell().info("Retained application-owned source:\n" + Enum.mapJoin(retained, "\n", function(path:String):String return "  * " + path));
		}
	}
}
