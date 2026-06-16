package stdlib_parity.upstream;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Macro adapter for checked-in upstream Haxe `unitstd` expression specs.
 *
 * Upstream files are intentionally kept as close as possible to their original
 * `.unit.hx` form. This adapter parses those expression files at macro time and
 * lowers assertion-shaped expressions (`a == b`, `t(expr)`, `f(expr)`, etc.) to
 * the local Haxe-authored ExUnit API, so the final assertions execute on BEAM.
 */
class UpstreamUnitStdMacro {
	public static macro function assertSpec(relativePath:String):Expr {
		var fixturePath = fixturePath(relativePath);
		if (!sys.FileSystem.exists(fixturePath)) {
			Context.error('Missing upstream unitstd fixture: ${fixturePath}', Context.currentPos());
		}

		var source = sys.io.File.getContent(fixturePath);
		var parsed = Context.parseInlineString("{\n" + source + "\n}", Context.currentPos());
		return transform(parsed, relativePath);
	}

	#if macro
	static function fixturePath(relativePath:String):String {
		return haxe.io.Path.join([Sys.getCwd(), "test/upstream_unitstd/upstream", relativePath]);
	}

	static function transform(expression:Expr, relativePath:String):Expr {
		return switch expression.expr {
			case EBlock(expressions):
				{expr: EBlock([for (statement in expressions) transformStatement(statement, relativePath)]), pos: expression.pos};
			default:
				transformStatement(expression, relativePath);
		}
	}

	static function transformStatement(expression:Expr, relativePath:String):Expr {
		return switch expression.expr {
			case EBinop(OpEq, left, right):
				assertTrue({expr: EBinop(OpEq, left, right), pos: expression.pos}, expression, relativePath);

			case EBinop(OpNotEq, left, right):
				assertTrue({expr: EBinop(OpNotEq, left, right), pos: expression.pos}, expression, relativePath);

			case EBinop((OpGt | OpGte | OpLt | OpLte), left, right):
				assertTrue({expr: expression.expr, pos: expression.pos}, expression, relativePath);

			case ECall({expr: EConst(CIdent("t"))}, [value]):
				assertTrue(value, expression, relativePath);

			case ECall({expr: EConst(CIdent("f"))}, [value]):
				assertFalse(value, expression, relativePath);

			case ECall({expr: EConst(CIdent("eq"))}, [expected, actual]):
				assertTrue({expr: EBinop(OpEq, actual, expected), pos: expression.pos}, expression, relativePath);

			case ECall({expr: EConst(CIdent("neq"))}, [expected, actual]):
				assertTrue({expr: EBinop(OpNotEq, actual, expected), pos: expression.pos}, expression, relativePath);

			case ECall({expr: EConst(CIdent("exc"))}, [body]):
				macro haxe.test.Assert.raises(function() {
					$body;
				}, null, $v{message(expression, relativePath)});

			case EThrow(value):
				macro haxe.test.Assert.raises(function() {
					throw $value;
				}, null, $v{message(expression, relativePath)});

			case EBlock(expressions):
				{expr: EBlock([for (statement in expressions) transformStatement(statement, relativePath)]), pos: expression.pos};

			case EIf(condition, thenExpression, elseExpression):
				{
					expr: EIf(condition, transformStatement(thenExpression, relativePath),
						elseExpression == null ? null : transformStatement(elseExpression, relativePath)),
					pos: expression.pos
				};

			case EWhile(condition, body, normalWhile):
				{expr: EWhile(condition, transformStatement(body, relativePath), normalWhile), pos: expression.pos};

			case EFor(iterator, body):
				{expr: EFor(iterator, transformStatement(body, relativePath)), pos: expression.pos};

			case ETry(body, catches):
				{
					expr: ETry(transformStatement(body, relativePath), [
						for (handler in catches)
							{
								name: handler.name,
								type: handler.type,
								expr: transformStatement(handler.expr, relativePath)
							}
					]),
					pos: expression.pos
				};

			case ESwitch(value, cases, defaultExpression):
				{
					expr: ESwitch(value, [
						for (caseBlock in cases)
							{
								values: caseBlock.values,
								guard: caseBlock.guard,
								expr: transformStatement(caseBlock.expr, relativePath)
							}
					],
						defaultExpression == null ? null : transformStatement(defaultExpression, relativePath)),
					pos: expression.pos
				};

			default:
				expression;
		}
	}

	static function assertTrue(condition:Expr, source:Expr, relativePath:String):Expr {
		return macro haxe.test.Assert.isTrue($condition, $v{message(source, relativePath)});
	}

	static function assertFalse(condition:Expr, source:Expr, relativePath:String):Expr {
		return macro haxe.test.Assert.isFalse($condition, $v{message(source, relativePath)});
	}

	static function message(source:Expr, relativePath:String):String {
		var location = Context.getPosInfos(source.pos);
		return 'upstream unitstd ${relativePath} at ${workspaceRelativePath(location.file)}:${location.min}';
	}

	static function workspaceRelativePath(path:String):String {
		var workspace = haxe.io.Path.normalize(Sys.getCwd());
		var normalizedPath = haxe.io.Path.normalize(path);
		var workspacePrefix = workspace + "/";
		if (StringTools.startsWith(normalizedPath, workspacePrefix)) {
			return normalizedPath.substr(workspacePrefix.length);
		}
		return normalizedPath;
	}
	#end
}
