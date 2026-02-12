package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * HxxModeResolver
 *
 * Centralizes how template authoring modes are selected.
 *
 * Selection:
 * - `@:hxx_mode("...")` on a function overrides the class-level mode.
 * - `-D hxx_mode=<value>` may set a global default (migration tooling).
 */
class HxxModeResolver {
	public static inline var META_NAME = ":hxx_mode";

	public static function parseModeString(value:String, pos:Position):HxxMode {
		if (value == null) {
			Context.error("@:hxx_mode expects a string literal: @:hxx_mode(\"balanced\"|\"tsx\"|\"metal\")", pos);
			return HxxMode.Balanced;
		}
		return switch (StringTools.trim(value).toLowerCase()) {
			case "balanced": HxxMode.Balanced;
			case "tsx": HxxMode.Tsx;
			case "metal": HxxMode.Metal;
			case other:
				Context.error('Unknown @:hxx_mode("' + other + '"). Expected "balanced", "tsx", or "metal".', pos);
				HxxMode.Balanced;
		};
	}

	public static function extractModeFromMetaEntries(entries:Null<Array<MetadataEntry>>):Null<HxxMode> {
		if (entries == null)
			return null;
		for (e in entries) {
			if (e == null)
				continue;
			if (e.name != META_NAME && e.name != "hxx_mode")
				continue;
			if (e.params == null || e.params.length != 1) {
				Context.error("@:hxx_mode expects exactly 1 string argument: @:hxx_mode(\"balanced\"|\"tsx\"|\"metal\")", e.pos);
				return null;
			}
			return switch (e.params[0].expr) {
				case EConst(CString(s, _)):
					parseModeString(s, e.params[0].pos);
				default:
					Context.error("@:hxx_mode expects a string literal: @:hxx_mode(\"balanced\"|\"tsx\"|\"metal\")", e.params[0].pos);
					null;
			};
		}
		return null;
	}

	public static function extractModeFromMetaAccess(meta:Null<MetaAccess>):Null<HxxMode> {
		if (meta == null)
			return null;
		return extractModeFromMetaEntries(meta.get());
	}

	static function findMethodField(cls:ClassType, methodName:String):Null<ClassField> {
		if (cls == null || methodName == null || methodName.length == 0)
			return null;
		for (f in cls.statics.get())
			if (f != null && f.name == methodName)
				return f;
		for (f in cls.fields.get())
			if (f != null && f.name == methodName)
				return f;
		return null;
	}

	public static function resolveFromMacroContext():HxxMode {
		var localClassRef = Context.getLocalClass();
		var cls:Null<ClassType> = localClassRef != null ? localClassRef.get() : null;
		var methodName = Context.getLocalMethod();
		var field:Null<ClassField> = (cls != null && methodName != null) ? findMethodField(cls, methodName) : null;
		return resolveFromTypes(cls, field);
	}

	public static function resolveFromTypes(cls:Null<ClassType>, field:Null<ClassField>):HxxMode {
		var fromField = (field != null) ? extractModeFromMetaAccess(field.meta) : null;
		if (fromField != null)
			return fromField;

		var fromClass = (cls != null) ? extractModeFromMetaAccess(cls.meta) : null;
		if (fromClass != null)
			return fromClass;

		var defined = Context.definedValue("hxx_mode");
		if (defined != null)
			return parseModeString(defined, Context.currentPos());

		return HxxMode.Balanced;
	}

	public static function hasAllowHeexMeta(cls:Null<ClassType>, field:Null<ClassField>):Bool {
		if (field != null && field.meta != null && field.meta.has(":allow_heex"))
			return true;
		if (cls != null && cls.meta != null && cls.meta.has(":allow_heex"))
			return true;
		return false;
	}

	public static function allowRawHeexMarkers(mode:HxxMode, allowHeexRequested:Bool, globalAllowHeex:Bool):Bool {
		return switch (mode) {
			case Metal:
				true;
			case Balanced: allowHeexRequested || globalAllowHeex;
			case Tsx:
				false;
			default:
				false;
		};
	}
}
#end
