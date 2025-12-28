package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SafePubSubConverterCaptureTransforms
 *
 * WHAT
 * - Ensure Phoenix.SafePubSub.parse_with_converter/2 is called with a function
 *   capture as its second argument, not a bare atom.
 *
 * WHY
 * - Haxe function identifiers (e.g., parseMessageImpl) can lower to atoms when
 *   passed as values. Elixir expects a function for `message_parser` and will
 *   crash if given an atom. We rewrite the second argument to an ECapture
 *   (&__MODULE__.func/arity) when a bare identifier is detected.
 *
 * HOW
 * - Find ERemoteCall(Mod, "parse_with_converter", [msg, parser]). If `parser`
 *   is an EVar("name"), rewrite to ECapture(ERemoteCall(__MODULE__, name, []), 1).
 * - If parser is already an ECapture, leave unchanged. If parser is a fully
 *   qualified remote call target (Module.func), wrap in ECapture with arity 1.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class SafePubSubConverterCaptureTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, func, args) if ((func == "parse_with_converter" || func == "parseWithConverter") && args != null && args.length == 2 && isSafePubSub(mod)):
                    var msgArg = args[0];
                    var parserArg = args[1];
                    var captured = switch (parserArg.def) {
                        case ECapture(_, _): parserArg; // already correct
                        case EVar(name):
                            // &__MODULE__.snake_name/1
                            var sname = reflaxe.elixir.ast.NameUtils.toSnakeCase(name);
                            makeAST(ECapture(makeAST(ERemoteCall(makeAST(EVar("__MODULE__")), sname, [])), 1));
                        case ERemoteCall(tgt, pname, _):
                            // &Module.snake_pname/1
                            var sp = reflaxe.elixir.ast.NameUtils.toSnakeCase(pname);
                            makeAST(ECapture(makeAST(ERemoteCall(tgt, sp, [])), 1));
                        case EAtom(atomName):
                            // Atoms like :"todo_pub_sub.parse_message_impl" → &__MODULE__.parse_message_impl/1
                            var atomStr = Std.string(atomName);
                            var idx = atomStr.lastIndexOf(".");
                            var fnName = idx >= 0 ? atomStr.substr(idx + 1) : atomStr;
                            if (fnName != null && fnName.length > 0)
                                makeAST(ECapture(makeAST(ERemoteCall(makeAST(EVar("__MODULE__")), fnName, [])), 1))
                            else
                                parserArg;
                        case EString(str) | ECharlist(str):
                            // In case builder lowered to string/charlist but printer will atomize
                            var sidx = str.lastIndexOf(".");
                            var sfn = sidx >= 0 ? str.substr(sidx + 1) : str;
                            if (sfn != null && sfn.length > 0)
                                makeAST(ECapture(makeAST(ERemoteCall(makeAST(EVar("__MODULE__")), sfn, [])), 1))
                            else
                                parserArg;
                        default:
                            parserArg;
                    };
                    var rewritten = makeASTWithMeta(ERemoteCall(mod, func, [msgArg, captured]), n.metadata, n.pos);
                    #if debug_ast_transformer
                    #end
                    rewritten;
                // Also handle local call forms: parse_with_converter(msg, parser)
                case ECall(target, funcName, callArgs) if ((target == null) && (funcName == "parse_with_converter" || funcName == "parseWithConverter") && callArgs != null && callArgs.length == 2):
                    var messageArgLocal = callArgs[0];
                    var parserArgLocal = callArgs[1];
                    var capturedParser = switch (parserArgLocal.def) {
                        case ECapture(_, _): parserArgLocal;
                        case EVar(varName):
                            var sname2 = reflaxe.elixir.ast.NameUtils.toSnakeCase(varName);
                            makeAST(ECapture(makeAST(ERemoteCall(makeAST(EVar("__MODULE__")), sname2, [])), 1));
                        case ERemoteCall(targetForCapture, parserFuncName, _):
                            var sp2 = reflaxe.elixir.ast.NameUtils.toSnakeCase(parserFuncName);
                            makeAST(ECapture(makeAST(ERemoteCall(targetForCapture, sp2, [])), 1));
                        case EAtom(atomValue):
                            var atomString = Std.string(atomValue);
                            var dotIndex = atomString.lastIndexOf(".");
                            var functionName = dotIndex >= 0 ? atomString.substr(dotIndex + 1) : atomString;
                            if (functionName != null && functionName.length > 0)
                                makeAST(ECapture(makeAST(ERemoteCall(makeAST(EVar("__MODULE__")), functionName, [])), 1))
                            else
                                parserArgLocal;
                        case EString(str) | ECharlist(str):
                            var dotIndex2 = str.lastIndexOf(".");
                            var functionName2 = dotIndex2 >= 0 ? str.substr(dotIndex2 + 1) : str;
                            if (functionName2 != null && functionName2.length > 0)
                                makeAST(ECapture(makeAST(ERemoteCall(makeAST(EVar("__MODULE__")), functionName2, [])), 1))
                            else
                                parserArgLocal;
                        default: parserArgLocal;
                    };
                    var rewrittenCall = makeASTWithMeta(ECall(null, funcName, [messageArgLocal, capturedParser]), n.metadata, n.pos);
#if debug_ast_transformer
#end
                    rewrittenCall;
                default:
                    n;
            }
        });
    }

    static function isSafePubSub(mod: ElixirAST): Bool {
        return switch (mod.def) {
            case EVar(m) if (m == "Phoenix.SafePubSub" || m == "SafePubSub"): true;
            default: false;
        };
    }
}

#end
