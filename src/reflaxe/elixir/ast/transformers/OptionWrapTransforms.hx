package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * OptionWrapParseFunctions
 *
 * WHAT
 * - Wraps return values of parse_* helper functions into {:some, value} or :none
 *   to align with callers that pattern-match on {:some, x} | :none.
 *
 * WHY
 * - Some generated parse_* functions return raw atoms/tuples and :none, while
 *   their callers expect Option-like results {:some, v} | :none. This mismatch
 *   produces "clause will never match" warnings. Wrapping non-:none results fixes it
 *   generically without app coupling.
 *
 * HOW
 * - Detect EDef/EDefp with name starting with "parse_".
 * - Find top-level case results inside the body and wrap any branch result that is not :none
 *   into ETuple([EAtom("some"), result]).
 * - Handles both direct case bodies and case assigned to a temp that is immediately returned.
 *
 * EXAMPLES
 *   defp parse_foo(x) do
 *     case x do
 *       "a" -> :a
 *       _ -> :none
 *     end
 *   end
 *   => wraps to
 *   case x do
 *     "a" -> {:some, :a}
 *     _ -> :none
 *   end
 */
class OptionWrapTransforms {
    public static function optionWrapParseFunctionsPass(ast: ElixirAST): ElixirAST {
        // Detect if a value AST already looks like an Option.t tuple
        inline function isAlreadyOption(val: ElixirAST): Bool {
            return switch (val.def) {
                case ETuple(elements) if (elements.length >= 1):
                    switch (elements[0].def) {
                        case EAtom(tag) if (tag == "some" || tag == ":some" || tag == "none" || tag == ":none"): true;
                        default: false;
                    }
                default: false;
            };
        }
        // Wrap a value expression into {:some, v} unless it's :none
        inline function wrapValueIfNeeded(val: ElixirAST): ElixirAST {
            if (isAlreadyOption(val)) return val;
            return switch (val.def) {
                case EAtom(atom) if (atom == "none" || atom == ":none"):
                    // Normalize None to tuple form {:none}
                    makeAST(ETuple([ makeAST(EAtom("none")) ]));
                default:
                    makeAST(ETuple([ makeAST(EAtom("some")), val ]));
            };
        }

        // For blocks, wrap the last expression when it's a simple value
        function wrapBlockLastExpr(b: ElixirAST): ElixirAST {
            return switch (b.def) {
                case EBlock(stmts) if (stmts.length > 0):
                    var out = stmts.copy();
                    var last = out.pop();
                    // Only wrap when last is a value or tuple; keep control structures as-is
                    out.push(wrapValueIfNeeded(last));
                    makeASTWithMeta(EBlock(out), b.metadata, b.pos);
                default:
                    b;
            }
        }
        function wrapCase(c: ElixirAST): ElixirAST {
            return ElixirASTTransformer.transformNode(c, function(n: ElixirAST): ElixirAST {
                return switch (n.def) {
                    case EMatch(pat, {def: ECase(target, clauses)}):
                        var wrapped = [];
                        for (cl in clauses) {
                            var b = cl.body;
                            var nb = isAlreadyOption(b) ? b : wrapValueIfNeeded(b);
                            wrapped.push({ pattern: cl.pattern, guard: cl.guard, body: nb });
                        }
                        makeASTWithMeta(EMatch(pat, makeAST(ECase(target, wrapped))), n.metadata, n.pos);
                    case ECase(target, clauses):
                        var wrapped = [];
                        for (cl in clauses) {
                            var body = cl.body;
                            var newBody = isAlreadyOption(body) ? body : switch (body.def) {
                                case EBlock(_): wrapBlockLastExpr(body);
                                default: wrapValueIfNeeded(body);
                            };
                            wrapped.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                        }
                        makeASTWithMeta(ECase(target, wrapped), n.metadata, n.pos);
                    case EIf(cond, thenB, elseB):
                        function wrapBranch(b: ElixirAST): ElixirAST {
                            return isAlreadyOption(b) ? b : switch (b.def) {
                                case EBlock(_): wrapBlockLastExpr(b);
                                default: wrapValueIfNeeded(b);
                            };
                        }
                        var newThen = wrapBranch(thenB);
                        var newElse = elseB != null ? wrapBranch(elseB) : elseB;
                        makeASTWithMeta(EIf(cond, newThen, newElse), n.metadata, n.pos);
                    default:
                        n;
                }
            });
        }

        function processBody(body: ElixirAST): ElixirAST {
            return switch (body.def) {
                case EBlock(stmts):
                    var out: Array<ElixirAST> = [];
                    for (s in stmts) out.push(wrapCase(s));
                    makeASTWithMeta(EBlock(out), body.metadata, body.pos);
                default:
                    wrapCase(body);
            }
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name != null && StringTools.startsWith(name, "parse_")):
                    makeASTWithMeta(EDef(name, args, guards, processBody(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body) if (name != null && StringTools.startsWith(name, "parse_")):
                    makeASTWithMeta(EDefp(name, args, guards, processBody(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end
