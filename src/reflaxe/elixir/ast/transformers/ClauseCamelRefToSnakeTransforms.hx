package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ClauseCamelRefToSnakeTransforms
 *
 * WHAT
 * - Within a case clause, rewrite camelCase references in the body to the
 *   snake_case name of an existing clause binder when they match by snake casing.
 *
 * WHY
 * - Keeps identifiers consistent and prevents undefined references when body
 *   uses camelCase while the binder is snake_case.
 *
 * HOW
 * - For each ECase clause, collect binder names from the pattern. For each
 *   EVar in the clause body, if toSnake(name) equals a binder name and name != binder,
 *   rewrite to the binder name.
 */
class ClauseCamelRefToSnakeTransforms {
    public static function clauseCamelRefToSnakePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var binders = collectPatternBinders(cl.pattern);
                        var set = new Map<String, Bool>();
                        for (b in binders) set.set(b, true);
                        var newBody = ElixirASTTransformer.transformNode(cl.body, function(n: ElixirAST): ElixirAST {
                            return switch (n.def) {
                                case EVar(v):
                                    var snake = toSnake(v);
                                    if (snake != v && set.exists(snake)) {
                                        makeASTWithMeta(EVar(snake), n.metadata, n.pos);
                                    } else n;
                                default: n;
                            }
                        });
                        newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function collectPatternBinders(p: EPattern): Array<String> {
        var out: Array<String> = [];
        function walk(px: EPattern) {
            switch (px) {
                case PVar(n): out.push(n);
                case PTuple(es): for (e in es) walk(e);
                case PList(es): for (e in es) walk(e);
                case PCons(h, t): walk(h); walk(t);
                case PMap(kvs): for (kv in kvs) walk(kv.value);
                case PStruct(_, fs): for (f in fs) walk(f.value);
                case PPin(inner): walk(inner);
                default:
            }
        }
        walk(p);
        return out;
    }

    static function toSnake(s: String): String {
        if (s == null || s.length == 0) return s;
        var buf = new StringBuf();
        for (i in 0...s.length) {
            var c = s.substr(i, 1);
            var lower = c.toLowerCase();
            var upper = c.toUpperCase();
            if (c == upper && c != lower) {
                if (i != 0) buf.add("_");
                buf.add(lower);
            } else {
                buf.add(c);
            }
        }
        return buf.toString();
    }
}

#end
