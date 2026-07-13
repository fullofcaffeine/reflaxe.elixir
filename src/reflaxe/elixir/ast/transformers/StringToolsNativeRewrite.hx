package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StringToolsNativeRewrite
 *
 * WHAT
 * - Rewrites StringTools.ltrim/rtrim bodies to call Elixir's native
 *   String.trim_leading/trim_trailing for idiomatic and robust behavior.
 *
 * WHY
 * - Builder/loop transforms for while→reduce_while introduced fragile locals
 *   (e.g., len/result) in the generated StringTools module. Instead of fighting
 *   the loop pattern here, we leverage Elixir's standard library directly.
 * - This follows the project philosophy for pragmatic stdlib implementation.
 *
 * HOW
 * - Detect def ltrim(s) and def rtrim(s) in module StringTools and replace their
 *   bodies with a single call to String.trim_leading(s) or String.trim_trailing(s).
 * - is_space/2 is left intact; new ltrim/rtrim no longer depend on it.
 * - Inline `substr` calls evaluate their source exactly once and calculate the
 *   source length only when negative, omitted, dynamic, or clamped bounds need
 *   it. A fixed `substr(0, positiveLength)` lowers directly to `String.slice/3`
 *   without an unused length binding.
 *
 * EXAMPLES
 * Haxe (caller):
 *   final a = StringTools.ltrim("  hi");
 *   final b = StringTools.rtrim("yo  ");
 *
 * Generated Elixir BEFORE (problematic):
 *   def ltrim(s) do
 *     l = length(s)
 *     r = 0
 *     Enum.reduce_while(...)
 *     _len = (l - r)
 *     if Kernel.is_nil(len), do: String.slice(s, r..-1), else: String.slice(s, r, len)
 *   end
 *
 * Generated Elixir AFTER (idiomatic):
 *   def ltrim(s), do: String.trim_leading(s)
 *   def rtrim(s), do: String.trim_trailing(s)
 */
class StringToolsNativeRewrite {
	public static function rewriteRuntimeCalls(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, rewriteRuntimeCallNode);
	}

	public static function rewriteTrimPass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(node:ElixirAST):ElixirAST {
			return switch (node.def) {
				case EModule(name, attrs, body) if (name == "StringTools"):
					var newBody:Array<ElixirAST> = [];
					for (b in body)
						newBody.push(rewriteDef(b));
					makeASTWithMeta(EModule(name, attrs, newBody), node.metadata, node.pos);
				case EDefmodule(name, doBlock) if (name == "StringTools"):
					makeASTWithMeta(EDefmodule(name, rewriteDef(doBlock)), node.metadata, node.pos);
				default:
					node;
			}
		});
	}

	static function rewriteRuntimeCallNode(node:ElixirAST):ElixirAST {
		return switch (node.def) {
			case ERemoteCall({def: EVar("StringTools")}, "haxe_substr", args) if (args.length == 3):
				makeASTWithMeta(haxeSubstrInline(args[0], args[1], args[2], true).def, node.metadata, node.pos);
			case ERemoteCall({def: EVar("StringTools")}, "haxe_substr_non_nil_len", args) if (args.length == 3):
				makeASTWithMeta(haxeSubstrInline(args[0], args[1], args[2], false).def, node.metadata, node.pos);
			default:
				node;
		}
	}

	static function rewriteDef(n:ElixirAST):ElixirAST {
		return switch (n.def) {
			case EDef(fnName, params, guards, body) if (fnName == "ltrim" && params.length == 1):
				var call = makeAST(ERemoteCall(makeAST(EVar("String")), "trim_leading", [paramVar(params[0])]));
				makeASTWithMeta(EDef(fnName, params, guards, call), n.metadata, n.pos);
			case EDef(fnName, params, guards, body) if (fnName == "rtrim" && params.length == 1):
				var call = makeAST(ERemoteCall(makeAST(EVar("String")), "trim_trailing", [paramVar(params[0])]));
				makeASTWithMeta(EDef(fnName, params, guards, call), n.metadata, n.pos);
			case EDef(fnName, params, guards, body) if (fnName == "is_space" && params.length == 2):
				// Normalize binders to s,pos to avoid underscore/body mismatches
				var newParams:Array<EPattern> = [PVar("s"), PVar("pos")];
				var sVar = makeAST(EVar("s"));
				var posVar = makeAST(EVar("pos"));
				var codeVar = makeAST(EVar("code"));
				var charlist = makeAST(ERemoteCall(makeAST(EVar("String")), "to_charlist", [sVar]));
				var enumAt = makeAST(ERemoteCall(makeAST(EVar("Enum")), "at", [charlist, posVar]));
				var cond = makeAST(EBinary(Or,
					makeAST(EBinary(And, makeAST(EBinary(Greater, codeVar, makeAST(EInteger(8)))), makeAST(EBinary(Less, codeVar, makeAST(EInteger(14)))))),
					makeAST(EBinary(Equal, codeVar, makeAST(EInteger(32))))));
				var codeCase = makeAST(ECase(enumAt, [
					{pattern: PLiteral(makeAST(ENil)), guard: null, body: makeAST(EBoolean(false))},
					{pattern: PVar("code"), guard: null, body: cond}
				]));
				var isNegative = makeAST(EBinary(Less, posVar, makeAST(EInteger(0))));
				makeASTWithMeta(EDef(fnName, newParams, guards, makeAST(EIf(isNegative, makeAST(EBoolean(false)), codeCase))), n.metadata, n.pos);
			default:
				n;
		}
	}

	static function haxeSubstrInline(source:ElixirAST, pos:ElixirAST, len:ElixirAST, lenMayBeNil:Bool):ElixirAST {
		var sourceVar = makeAST(EVar("reflaxe_string_source"));
		var lengthVar = makeAST(EVar("reflaxe_string_length"));
		var startVar = makeAST(EVar("reflaxe_string_start"));
		var countVar = makeAST(EVar("reflaxe_string_count"));
		var posInt = intLiteral(pos);
		var lenInt = intLiteral(len);
		var lenIsNil = switch (len.def) {
			case ENil: true;
			default: false;
		}
		var lengthNeeded = posInt == null || posInt != 0 || lenIsNil || lenInt == null || lenInt < 0;
		var statements:Array<ElixirAST> = [makeAST(EMatch(PVar("reflaxe_string_source"), source))];
		if (lengthNeeded) {
			statements.push(makeAST(EMatch(PVar("reflaxe_string_length"), makeAST(ERemoteCall(makeAST(EVar("String")), "length", [sourceVar])))));
		}

		var posExpr:ElixirAST;
		if (posInt == null) {
			statements.push(makeAST(EMatch(PVar("reflaxe_string_pos"), pos)));
			posExpr = makeAST(EVar("reflaxe_string_pos"));
		} else {
			posExpr = makeAST(EInteger(posInt));
		}

		var lenExpr:ElixirAST = null;
		if (!lenIsNil) {
			if (lenInt == null) {
				statements.push(makeAST(EMatch(PVar("reflaxe_string_len"), len)));
				lenExpr = makeAST(EVar("reflaxe_string_len"));
			} else {
				lenExpr = makeAST(EInteger(lenInt));
			}
		}

		var startExpr = if (posInt != null) {
			if (posInt < 0) {
				makeAST(ECall(null, "max", [
					makeAST(EBinary(Add, lengthVar, makeAST(EInteger(posInt)))),
					makeAST(EInteger(0))
				]));
			} else if (posInt == 0) {
				makeAST(EInteger(0));
			} else {
				makeAST(ECall(null, "min", [makeAST(EInteger(posInt)), lengthVar]));
			}
		} else {
			var maxStart = makeAST(ECall(null, "max", [makeAST(EBinary(Add, lengthVar, posExpr)), makeAST(EInteger(0))]));
			makeAST(ECond([
				{condition: makeAST(EBinary(Less, posExpr, makeAST(EInteger(0)))), body: maxStart},
				{condition: makeAST(EBinary(Greater, posExpr, lengthVar)), body: lengthVar},
				{condition: makeAST(EBoolean(true)), body: posExpr}
			]));
		}

		var countExpr = if (lenIsNil) {
			makeAST(EBinary(Subtract, lengthVar, startVar));
		} else if (lenInt != null) {
			if (lenInt < 0) {
				makeAST(ECall(null, "max", [
					makeAST(EBinary(Subtract, makeAST(EBinary(Add, lengthVar, makeAST(EInteger(lenInt)))), startVar)),
					makeAST(EInteger(0))
				]));
			} else {
				makeAST(EInteger(lenInt));
			}
		} else if (lenMayBeNil) {
			var nilLen = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [lenExpr]));
			var negativeCount = makeAST(ECall(null, "max", [
				makeAST(EBinary(Subtract, makeAST(EBinary(Add, lengthVar, lenExpr)), startVar)),
				makeAST(EInteger(0))
			]));
			makeAST(ECond([
				{condition: nilLen, body: makeAST(EBinary(Subtract, lengthVar, startVar))},
				{condition: makeAST(EBinary(Less, lenExpr, makeAST(EInteger(0)))), body: negativeCount},
				{condition: makeAST(EBoolean(true)), body: lenExpr}
			]));
		} else {
			var negativeCount = makeAST(ECall(null, "max", [
				makeAST(EBinary(Subtract, makeAST(EBinary(Add, lengthVar, lenExpr)), startVar)),
				makeAST(EInteger(0))
			]));
			makeAST(ECond([
				{condition: makeAST(EBinary(Less, lenExpr, makeAST(EInteger(0)))), body: negativeCount},
				{condition: makeAST(EBoolean(true)), body: lenExpr}
			]));
		}

		statements.push(makeAST(EMatch(PVar("reflaxe_string_start"), startExpr)));
		statements.push(makeAST(EMatch(PVar("reflaxe_string_count"), countExpr)));
		statements.push(makeAST(ERemoteCall(makeAST(EVar("String")), "slice", [sourceVar, startVar, countVar])));
		var body = makeAST(EBlock(statements));
		return makeAST(ECall(makeAST(EFn([{args: [], guard: null, body: body}])), "", []));
	}

	static function intLiteral(ast:ElixirAST):Null<Int> {
		return switch (ast.def) {
			case EInteger(value): value;
			default: null;
		}
	}

	static inline function paramVar(p:EPattern):ElixirAST {
		return switch (p) {
			case PVar(name): makeAST(EVar(name));
			default: makeAST(EVar("s"));
		}
	}
}
#end
