package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;

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
    public static function rewriteTrimPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EModule(name, attrs, body) if (name == "StringTools"):
                    var newBody: Array<ElixirAST> = [];
                    for (b in body) newBody.push(rewriteDef(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), node.metadata, node.pos);
                case EDefmodule(name, doBlock) if (name == "StringTools"):
                    makeASTWithMeta(EDefmodule(name, rewriteDef(doBlock)), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function rewriteDef(n: ElixirAST): ElixirAST {
        return switch (n.def) {
            case EDef(fnName, params, guards, body) if (fnName == "ltrim" && params.length == 1):
                var call = makeAST(ERemoteCall(makeAST(EVar("String")), "trim_leading", [paramVar(params[0])]));
                makeASTWithMeta(EDef(fnName, params, guards, call), n.metadata, n.pos);
            case EDef(fnName, params, guards, body) if (fnName == "rtrim" && params.length == 1):
                var call = makeAST(ERemoteCall(makeAST(EVar("String")), "trim_trailing", [paramVar(params[0])]));
                makeASTWithMeta(EDef(fnName, params, guards, call), n.metadata, n.pos);
            case EDef(fnName, params, guards, body) if (fnName == "is_space" && params.length == 2):
                // def is_space(s, pos) do
                //   (:binary.at(s, pos) > 8 and :binary.at(s, pos) < 14) or :binary.at(s, pos) == 32
                // end
                var sVar = paramVar(params[0]);
                var posVar = paramVar(params[1]);
                var atCall = function() return makeAST(ERemoteCall(makeAST(EAtom(ElixirAtom.raw("binary"))), "at", [sVar, posVar]));
                var cond = makeAST(EBinary(Or,
                    makeAST(EBinary(And, makeAST(EBinary(Greater, atCall(), makeAST(EInteger(8)))), makeAST(EBinary(Less, atCall(), makeAST(EInteger(14)))))),
                    makeAST(EBinary(Equal, atCall(), makeAST(EInteger(32))))
                ));
                makeASTWithMeta(EDef(fnName, params, guards, cond), n.metadata, n.pos);
            default:
                n;
        }
    }

    static inline function paramVar(p: EPattern): ElixirAST {
        return switch (p) {
            case PVar(name): makeAST(EVar(name));
            default: makeAST(EVar("s"));
        }
    }
}

#end
