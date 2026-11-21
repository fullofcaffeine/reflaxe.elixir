#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

/**
 * A build macro that defines a class and gives it the metadata of another
 * class, as some framework macros do. When `Base` is reused from the server
 * cache, the copied metadata includes Reflaxe's `@:reflaxe.typedIn` of `Base`.
 */
class Gen {
	public static function build():Array<Field> {
		final fields = Context.getBuildFields();
		var text = "";
		for (field in fields) {
			if (field.name != "v")
				continue;
			switch (field.kind) {
				case FFun(fn) if (fn.expr != null):
					function find(e:Expr):Void {
						switch (e.expr) {
							case EConst(CString(value, _)):
								text = value;
							case _:
								ExprTools.iter(e, find);
						}
					}
					find(fn.expr);
				case _:
			}
		}
		final baseMeta = switch (Context.getType("Base")) {
			case TInst(_.get() => base, _): base.meta.get();
			case _: [];
		}
		final companion = macro class HostCompanion {
			public static function label():String
				return "companion of " + $v{text};
		};
		companion.meta = baseMeta;
		Context.defineType(companion);
		return fields;
	}
}
#end
