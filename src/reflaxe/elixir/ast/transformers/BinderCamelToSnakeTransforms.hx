package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * BinderCamelToSnakeTransforms
 *
 * WHAT
 * - Renames camelCase clause-binder variables in case patterns to snake_case and
 *   updates body references within the same clause. Keeps naming idiomatic and
 *   avoids mixed-case locals.
 *
 * WHY
 * - Generators and inputs may produce camelCase binders (e.g., sortBy). Elixir uses
 *   snake_case for variables. A generic transform improves readability and fixes
 *   body references consistently without app coupling.
 *
 * HOW
 * - For each ECase clause: detect single or multiple PVar binders; for each binder with
 *   internal uppercase letters, compute snake_case and:
 *   - rename the pattern variable
 *   - replace EVar(oldName) with EVar(newName) in the clause body
 *
 * EXAMPLES
 * Haxe:
 *   switch (x) {
 *     case {userId: idValue}: idValue
 *   }
 * Elixir (before):
 *   case x do
 *     %{userId: idValue} -> idValue
 *   end
 * Elixir (after):
 *   case x do
 *     %{userId: id_value} -> id_value
 *   end
 */
class BinderCamelToSnakeTransforms {
    public static function binderCamelToSnakePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var renames = new Map<String, String>();
                        var newPattern = renamePatternBinders(cl.pattern, renames);
                        var newBody = (renames.keys().hasNext()) ? replaceBodyVars(cl.body, renames) : cl.body;
                        newClauses.push({ pattern: newPattern, guard: cl.guard, body: newBody });
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function renamePatternBinders(p: EPattern, renames: Map<String, String>): EPattern {
        return switch (p) {
            case PVar(n):
                var snake = toSnake(n);
                if (snake != n) {
                    renames.set(n, snake);
                    PVar(snake);
                } else p;
            case PTuple(es): PTuple([for (e in es) renamePatternBinders(e, renames)]);
            case PList(es): PList([for (e in es) renamePatternBinders(e, renames)]);
            case PCons(h, t): PCons(renamePatternBinders(h, renames), renamePatternBinders(t, renames));
            case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: renamePatternBinders(kv.value, renames) }]);
            case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: renamePatternBinders(f.value, renames) }]);
            case PPin(inner): PPin(renamePatternBinders(inner, renames));
            default: p;
        }
    }

    static function replaceBodyVars(body: ElixirAST, renames: Map<String, String>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (renames.exists(v)):
                    makeASTWithMeta(EVar(renames.get(v)), n.metadata, n.pos);
                default: n;
            }
        });
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
