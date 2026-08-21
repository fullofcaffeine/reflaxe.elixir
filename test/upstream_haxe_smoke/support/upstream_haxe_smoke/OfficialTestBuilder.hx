package upstream_haxe_smoke;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
#end

/** Marks official Haxe `test*` methods for ExUnit without changing test bodies. */
class OfficialTestBuilder {
	public static macro function build():Array<Field> {
		var fields = Context.getBuildFields();
		var localClass = Context.getLocalClass().get();
		localClass.meta.add(":exunit", [], localClass.pos);
		localClass.meta.add(":keep", [], localClass.pos);

		for (field in fields) {
			switch field.kind {
				case FFun(fn) if (StringTools.startsWith(field.name, "test")):
					field.meta.push({name: ":test", params: [macro $v{field.name}], pos: field.pos});
					field.meta.push({name: ":keep", params: [], pos: field.pos});
					if (fn.expr != null) {
						fn.expr = transformAssertions(fn.expr);
					}
				default:
			}
		}
		return fields;
	}

	#if macro
	static function transformAssertions(expression:Expr):Expr {
		var assertionMessage = message(expression);
		return switch expression.expr {
			case ECall({expr: EConst(CIdent("eq"))}, [expected, actual]):
				macro haxe.test.Assert.equals($expected, $actual, $v{assertionMessage});
			case ECall({expr: EConst(CIdent("feq"))}, [expected, actual]):
				macro haxe.test.Assert.inDelta($expected, $actual, 0.00001, $v{assertionMessage});
			case ECall({expr: EConst(CIdent("t"))}, [value]):
				macro haxe.test.Assert.isTrue($value, $v{assertionMessage});
			default:
				ExprTools.map(expression, transformAssertions);
		}
	}

	static function message(expression:Expr):String {
		var position = Context.getPosInfos(expression.pos);
		var path = StringTools.replace(position.file, "\\", "/");
		if (StringTools.startsWith(path, "src/")) {
			path = "tests/unit/src/" + path.substr(4);
		}
		return 'official Haxe ${path}:${position.min}';
	}
	#end
}
