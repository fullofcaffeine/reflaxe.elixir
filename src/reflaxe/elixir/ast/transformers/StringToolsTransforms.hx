package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ASTUtils;

/**
 * StringToolsTransforms
 *
 * WHAT
 * - Align EVar references with declared locals inside StringTools functions.
 *   If `_len` is declared and `len` is not, rewrite `len` → `_len` (similarly for `result`).
 *
 * WHY
 * - Intermediate transforms (e.g., loop desugaring) may introduce underscored locals
 *   while some references still target the base names.
 *
 * HOW
 * - For each function, collect declared names from patterns and `lhs = ...` matches,
 *   build a name→_name map, and rewrite EVar references accordingly.
 *
 * EXAMPLES
 * Elixir before:
 *   _len = l - r
 *   String.slice(s, r, len)
 *
 * Elixir after:
 *   _len = l - r
 *   String.slice(s, r, _len)
 */
class StringToolsTransforms {
    public static function fixLocalReferencesPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EModule(name, attrs, body) if (name == "StringTools"):
                    var newBody = [];
                    for (b in body) newBody.push(fixInDefs(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), node.metadata, node.pos);
                case EDefmodule(name, doBlock) if (name == "StringTools"):
                    makeASTWithMeta(EDefmodule(name, fixInDefs(doBlock)), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function fixInDefs(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(fnName, params, guards, body) | EDefp(fnName, params, guards, body):
                    var declared = new Map<String, Bool>();
                    ASTUtils.walk(body, function(x) {
                        switch (x.def) {
                            case EMatch(p, _): collect(p, declared);
                            case EBinary(Match, left, _):
                                switch (left.def) { case EVar(lhs): declared.set(lhs, true); default: }
                            default:
                        }
                    });

                    var rename = new Map<String, String>();
                    if (declared.exists("_len") && !declared.exists("len")) rename.set("len", "_len");
                    if (declared.exists("_result") && !declared.exists("result")) rename.set("result", "_result");

                    if (Lambda.count(rename) == 0) return n;

                    function tx(m: ElixirAST): ElixirAST {
                        return switch (m.def) {
                            case EVar(v) if (rename.exists(v)):
                                makeASTWithMeta(EVar(rename.get(v)), m.metadata, m.pos);
                            default:
                                m;
                        }
                    }
                    var newBody = ElixirASTTransformer.transformNode(body, tx);
                    switch (n.def) {
                        case EDef(name, p, g, _): makeASTWithMeta(EDef(name, p, g, newBody), n.metadata, n.pos);
                        case EDefp(name, p, g, _): makeASTWithMeta(EDefp(name, p, g, newBody), n.metadata, n.pos);
                        default: n;
                    }
                default:
                    n;
            }
        });
    }

    static function collect(p: EPattern, declared: Map<String, Bool>): Void {
        switch (p) {
            case PVar(n): declared.set(n, true);
            case PTuple(es) | PList(es): for (e in es) collect(e, declared);
            case PCons(h, t): collect(h, declared); collect(t, declared);
            case PMap(kvs): for (kv in kvs) collect(kv.value, declared);
            case PStruct(_, fs): for (f in fs) collect(f.value, declared);
            case PPin(inner): collect(inner, declared);
            default:
        }
    }
}

#end
