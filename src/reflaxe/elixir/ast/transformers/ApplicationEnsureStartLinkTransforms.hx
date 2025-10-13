package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * ApplicationEnsureStartLinkTransforms
 *
 * WHAT
 * - Ensures Application.start/2 ends with Supervisor.start_link(children, opts). If missing, appends it.
 *
 * SCOPE
 * - Modules whose name ends with ".Application" (framework-level pattern), function name == "start" and arity 2.
 */
class ApplicationEnsureStartLinkTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name != null && StringTools.endsWith(name, ".Application")):
                    var newBody:Array<ElixirAST> = [];
                    for (b in body) newBody.push(ensureInDef(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name != null && StringTools.endsWith(name, ".Application")):
                    var nb = ensureInBlock(doBlock);
                    makeASTWithMeta(EDefmodule(name, nb), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function ensureInBlock(doBlock: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(doBlock, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EBlock(stmts): makeASTWithMeta(EBlock([for (s in stmts) ensureInDef(s)]), x.metadata, x.pos);
                default: x;
            }
        });
    }

    static function ensureInDef(d: ElixirAST): ElixirAST {
        return switch (d.def) {
            case EDef(fname, args, guards, body) if (fname == "start" && args.length == 2):
                var hasStartLink = false;
                var childrenName: Null<String> = null;
                var transformed = ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
                    return switch (x.def) {
                        case ERemoteCall(mod, fn, _) if (fn == "start_link"):
                            hasStartLink = true; x;
                        case EBinary(Match, left, rhs):
                            switch (left.def) { case EVar(v) if (v == "children" || v == "_children"): childrenName = v; default: }
                            x;
                        case EMatch(PVar(v), rhs2):
                            if (v == "children" || v == "_children") childrenName = v;
                            x;
                        default:
                            x;
                    }
                });
                if (hasStartLink) return makeASTWithMeta(EDef(fname, args, guards, transformed), d.metadata, d.pos);
                // Append call using detected children or build empty list
                var childrenExpr = (childrenName != null) ? makeAST(EVar(childrenName)) : makeAST(EList([]));
                var opts = makeAST(EKeywordList([{ key: "strategy", value: makeAST(EAtom(ElixirAtom.fromString(":one_for_one"))) }]));
                var call = makeAST(ERemoteCall(makeAST(EVar("Supervisor")), "start_link", [childrenExpr, opts]));
                var newBody = switch (transformed.def) {
                    case EBlock(stmts): makeASTWithMeta(EBlock(stmts.concat([call])), transformed.metadata, transformed.pos);
                    default: makeAST( EBlock([transformed, call]) );
                };
                makeASTWithMeta(EDef(fname, args, guards, newBody), d.metadata, d.pos);
            default:
                d;
        }
    }
}

#end
