package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FnArgUnusedUnderscoreTransforms
 *
 * WHAT
 * - For anonymous function clauses, prefix unused pattern binders with underscore
 *   to prevent compiler warnings (e.g., fn _, {acc} -> ... end when acc unused).
 *
 * WHY
 * - Loop conversions (reduce_while, etc.) and render helpers can introduce
 *   unused pattern vars. Elixir warns, and CI treats warnings as errors.
 *
 * HOW
 * - For each EFn clause, collect PVar names in args; check usage in body; if a
 *   name is unused, rewrite its pattern occurrence to _name.
 *
 * EXAMPLES
 * Before:
 *   Enum.reduce(list, 0, fn x, acc -> acc end)  # x unused
 * After:
 *   Enum.reduce(list, 0, fn _x, acc -> acc end)
 */
class FnArgUnusedUnderscoreTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var names = collectNames(cl.args);
                        var used = new Map<String, Bool>();
                        markUsed(cl.body, used);
                        var rewrittenArgs = rewriteArgs(cl.args, names, used);
                        newClauses.push({args: rewrittenArgs, guard: cl.guard, body: cl.body});
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function collectNames(args: Array<EPattern>): Array<String> {
        var out = [];
        function visit(p: EPattern): Void {
            switch (p) {
                case PVar(name): out.push(name);
                case PTuple(els): for (e in els) visit(e);
                case PList(els): for (e in els) visit(e);
                case PCons(h, t): visit(h); visit(t);
                case PMap(pairs): for (pa in pairs) visit(pa.value);
                case PStruct(_, fields): for (f in fields) visit(f.value);
                case PAlias(name, pat): out.push(name); visit(pat);
                case PPin(inner): visit(inner);
                case PBinary(segs): for (s in segs) visit(s.pattern);
                case PWildcard | PLiteral(_):
            }
        }
        for (a in args) visit(a);
        return out;
    }

    static function markUsed(node: ElixirAST, used: Map<String, Bool>): Void {
        if (node == null || node.def == null) return;
        switch (node.def) {
            case EVar(name): used.set(name, true);
            case EBlock(stmts): for (s in stmts) markUsed(s, used);
            case EIf(c,t,e): markUsed(c, used); markUsed(t, used); if (e != null) markUsed(e, used);
            case ECase(expr, clauses):
                markUsed(expr, used);
                for (c in clauses) { if (c.guard != null) markUsed(c.guard, used); markUsed(c.body, used); }
            case EBinary(_, l, r): markUsed(l, used); markUsed(r, used);
            case EMatch(pat, rhs): markUsed(rhs, used);
            case ECall(tgt, _, args): if (tgt != null) markUsed(tgt, used); for (a in args) markUsed(a, used);
            case ERemoteCall(tgt2, _, args2): markUsed(tgt2, used); for (a2 in args2) markUsed(a2, used);
            case EList(els): for (el in els) markUsed(el, used);
            case ETuple(els): for (el in els) markUsed(el, used);
            case EMap(pairs): for (p in pairs) { markUsed(p.key, used); markUsed(p.value, used); }
            case EKeywordList(pairs): for (p in pairs) markUsed(p.value, used);
            case EStructUpdate(base, fields): markUsed(base, used); for (f in fields) markUsed(f.value, used);
            case EFn(clauses): for (cl in clauses) markUsed(cl.body, used);
            default:
        }
    }

    static function rewriteArgs(args: Array<EPattern>, names: Array<String>, used: Map<String, Bool>): Array<EPattern> {
        function rewrite(p: EPattern): EPattern {
            return switch (p) {
                case PVar(name):
                    if (!used.exists(name) && name != null && name.length > 0 && name.charAt(0) != '_') PVar('_' + name) else p;
                case PTuple(els): PTuple(els.map(rewrite));
                case PList(els): PList(els.map(rewrite));
                case PCons(h, t): PCons(rewrite(h), rewrite(t));
                case PMap(pairs): PMap(pairs.map(pa -> {key: pa.key, value: rewrite(pa.value)}));
                case PStruct(m, fields): PStruct(m, fields.map(f -> {key: f.key, value: rewrite(f.value)}));
                case PAlias(name, pat):
                    var newName = (!used.exists(name) && name.charAt(0) != '_') ? '_' + name : name;
                    PAlias(newName, rewrite(pat));
                case PPin(inner): PPin(rewrite(inner));
                case PBinary(segs): PBinary(segs.map(s -> {pattern: rewrite(s.pattern), size: s.size, type: s.type, modifiers: s.modifiers}));
                case PWildcard | PLiteral(_): p;
            }
        }
        return args.map(rewrite);
    }
}

#end
