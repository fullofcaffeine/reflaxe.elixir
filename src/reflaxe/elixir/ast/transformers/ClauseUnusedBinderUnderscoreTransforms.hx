package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

/**
 * ClauseUnusedBinderUnderscoreTransforms
 *
 * WHAT
 * - Prefix unused clause-binder variables with underscore to silence compiler warnings
 *   while preserving readability and scope.
 *
 * WHY
 * - Haxe-generated patterns may bind variables not referenced in the clause body.
 *   Elixir warns on unused vars; adding underscore is idiomatic.
 *
 * HOW
 * - For each case clause, collect body-used names, compare against pattern binders,
 *   and rewrite unused PVar(name) -> PVar("_" + name).
 *
 * EXAMPLES
 * Before: case x do {a, b} -> a end
 * After:  case x do {a, _b} -> a end
 */
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ClauseUnusedBinderUnderscoreTransforms
 *
 * WHAT
 * - Prefix unused case-pattern binders with underscore in a clause when they are
 *   not referenced in the clause body, eliminating unused-variable warnings.
 *
 * WHY
 * - Patterns like {:ok, value} frequently bind variables that the body does not use.
 *   Elixir warns on unused variables unless prefixed with underscore. This is generic
 *   and not app-specific.
 *
 * HOW
 * - For each ECase clause, collect pattern binders and body variable uses. For each
 *   binder not present in body uses, rename PVar(name) to PVar("_" + name).
 */
class ClauseUnusedBinderUnderscoreTransforms {
    public static function clauseUnusedBinderUnderscorePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var binders = collectPatternBinders(cl.pattern);
                        var used = collectUsedVars(cl.body);
                        var unused = [for (b in binders) if (used.indexOf(b) == -1) b];
                        var newPat = (unused.length > 0) ? underscoreBinders(cl.pattern, unused) : cl.pattern;
                        newClauses.push({ pattern: newPat, guard: cl.guard, body: cl.body });
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function underscoreBinders(p: EPattern, names: Array<String>): EPattern {
        return switch (p) {
            case PVar(n):
                if (names.indexOf(n) != -1 && n.charAt(0) != "_") PVar("_" + n) else p;
            case PTuple(es): PTuple([for (e in es) underscoreBinders(e, names)]);
            case PList(es): PList([for (e in es) underscoreBinders(e, names)]);
            case PCons(h, t): PCons(underscoreBinders(h, names), underscoreBinders(t, names));
            case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: underscoreBinders(kv.value, names) }]);
            case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: underscoreBinders(f.value, names) }]);
            case PPin(inner): PPin(underscoreBinders(inner, names));
            default: p;
        }
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

    static function collectUsedVars(body: ElixirAST): Array<String> {
        var names = new Map<String, Bool>();
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case EVar(v): names.set(v, true);
                default:
            }
            return n;
        }) != null ? [for (k in names.keys()) k] : [];
    }
}

#end
