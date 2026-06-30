package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.ast.NameUtils;

/**
 * Central PhoenixHx target-name derivation and validation.
 *
 * WHAT
 * - Derives app-facing Elixir module aliases from PhoenixHx metadata and
 *   project configuration such as `-D app_name=TodoApp`.
 *
 * WHY
 * - App code should not need fragile strings like
 *   `@:native("TodoAppWeb.TodoLive")` when PhoenixHx already knows that a class
 *   is a LiveView and the configured web module is `TodoAppWeb`.
 *
 * HOW
 * - Framework-owned annotations return a concrete target alias.
 * - True interop can still use `@:native`, but every app-facing alias/path can
 *   share the same validation and path conversion rules.
 */
class PhoenixTargetNames {
	public static function appModule():String {
		var value = Context.definedValue("app_name");
		if (value == null || StringTools.trim(value) == "")
			value = "MyApp";
		validateAlias(value, Context.currentPos(), "app_name");
		return value;
	}

	public static function webModule():String {
		var explicit = Context.definedValue("app_web_name");
		var value = explicit != null && StringTools.trim(explicit) != "" ? explicit : appModule() + "Web";
		validateAlias(value, Context.currentPos(), "app_web_name");
		return value;
	}

	public static function repoModule():String {
		return appModule() + ".Repo";
	}

	public static function appSnake():String {
		return NameUtils.toSnakeCase(appModule());
	}

	public static function webSnake():String {
		return NameUtils.toSnakeCase(webModule());
	}

	public static function aliasToPath(moduleAlias:String):String {
		validateAlias(moduleAlias, Context.currentPos(), "Elixir module alias");
		var parts = moduleAlias.split(".");
		var file = NameUtils.toSnakeCase(parts.pop()) + ".ex";
		if (parts.length == 0)
			return file;
		return parts.map(NameUtils.toSnakeCase).join("/") + "/" + file;
	}

	public static function packForAlias(moduleAlias:String):Array<String> {
		validateAlias(moduleAlias, Context.currentPos(), "Elixir module alias");
		var parts = moduleAlias.split(".");
		parts.pop();
		return parts.map(NameUtils.toSnakeCase);
	}

	public static function nameForAlias(moduleAlias:String):String {
		validateAlias(moduleAlias, Context.currentPos(), "Elixir module alias");
		var parts = moduleAlias.split(".");
		return parts[parts.length - 1];
	}

	public static function classTargetAlias(classType:ClassType):Null<String> {
		if (classType == null)
			return null;

		var app = appModule();
		var web = webModule();

		if (hasMeta(classType, ":application", "application"))
			return app + ".Application";
		if (hasMeta(classType, ":phoenixWebModule", "phoenixWebModule") || hasMeta(classType, ":phoenixWeb", "phoenixWeb"))
			return web;
		if (hasMeta(classType, ":endpoint", "endpoint"))
			return web + ".Endpoint";
		if (hasMeta(classType, ":router", "router"))
			return web + ".Router";
		if (hasMeta(classType, ":repo", "repo"))
			return app + ".Repo";
		if (hasMeta(classType, ":liveview", "liveview"))
			return web + "." + classType.name;
		if (hasMeta(classType, ":controller", "controller"))
			return web + "." + classType.name;
		if (hasMeta(classType, ":channel", "channel"))
			return web + "." + classType.name;
		if (hasMeta(classType, ":socket", "socket"))
			return web + "." + classType.name;
		if (hasMeta(classType, ":gettext", "gettext"))
			return web + ".Gettext";
		if (hasMeta(classType, ":presence", "presence"))
			return web + ".Presence";
		if (hasMeta(classType, ":component", "component"))
			return web + "." + classType.name;
		if (hasMeta(classType, ":schema", "schema"))
			return app + "." + classType.name;
		if (hasMeta(classType, ":exunit", "exunit") && Context.definedValue("app_name") != null)
			return app + "." + classType.name;

		switch (classType.kind) {
			case KModuleFields(_):
				return null;
			default:
		}

		if (isProjectPackage(classType) && Context.definedValue("app_name") != null) {
			if (classType.pack.indexOf("controllers") >= 0)
				return web + "." + classType.name;
			if (classType.pack.indexOf("channels") >= 0)
				return web + "." + classType.name;
			if (classType.pack.indexOf("i18n") >= 0 && classType.name == "Gettext")
				return web + ".Gettext";
			if (classType.pack.indexOf("infrastructure") >= 0 && isKnownWebInfrastructure(classType.name))
				return web + "." + classType.name;
			if (isKnownAppPackage(classType.pack) || classType.name == "SafeAssigns")
				return app + "." + classType.name;
			return app + "." + classType.name;
		}

		return null;
	}

	public static function nativeAlias(classType:ClassType):Null<String> {
		var entry = firstMeta(classType, ":native", "native");
		if (entry == null || entry.params == null || entry.params.length == 0)
			return null;
		return switch (entry.params[0].expr) {
			case EConst(CString(value, _)):
				value;
			default:
				Context.error("@:native expects an Elixir module alias string literal.", entry.params[0].pos);
				null;
		};
	}

	public static function validateAlias(moduleAlias:String, pos:Position, label:String):Void {
		if (moduleAlias == null || StringTools.trim(moduleAlias) == "")
			Context.error(label + " must not be empty.", pos);
		var parts = moduleAlias.split(".");
		for (part in parts) {
			if (part == "")
				Context.error(label + ' "$moduleAlias" contains an empty module segment.', pos);
			var first = part.charAt(0);
			if (first < "A" || first > "Z")
				Context.error(label + ' "$moduleAlias" must use Elixir alias segments that start with an uppercase letter.', pos);
			if (!~/^[A-Za-z_][A-Za-z0-9_]*$/.match(part))
				Context.error(label + ' "$moduleAlias" contains invalid Elixir alias segment "$part".', pos);
		}
	}

	static function isKnownWebInfrastructure(name:String):Bool {
		return switch (name) {
			case "Endpoint" | "Telemetry" | "UserSocket" | "ErrorHTML" | "ErrorJSON" | "LiveSession": true;
			default: false;
		};
	}

	static function isKnownAppPackage(pack:Array<String>):Bool {
		for (part in pack) {
			switch (part) {
				case "contexts" | "schemas" | "data" | "services" | "support" | "pubsub" | "shared" | "types":
					return true;
				default:
			}
		}
		return false;
	}

	static function isProjectPackage(classType:ClassType):Bool {
		if (classType.isExtern)
			return false;
		if (classType.name != null && StringTools.startsWith(classType.name, "_"))
			return false;
		if (classType.pack == null || classType.pack.length == 0)
			return false;
		return switch (classType.pack[0]) {
			case "haxe" | "sys" | "elixir" | "ecto" | "phoenix" | "plug" | "reflaxe": false;
			default: true;
		};
	}

	static function hasMeta(classType:ClassType, primary:String, alternate:String):Bool {
		return firstMeta(classType, primary, alternate) != null;
	}

	static function firstMeta(classType:ClassType, primary:String, alternate:String):Null<MetadataEntry> {
		if (classType == null || classType.meta == null)
			return null;
		var primaryEntries = classType.meta.extract(primary);
		if (primaryEntries != null && primaryEntries.length > 0)
			return primaryEntries[0];
		var alternateEntries = classType.meta.extract(alternate);
		if (alternateEntries != null && alternateEntries.length > 0)
			return alternateEntries[0];
		return null;
	}
}
#end
