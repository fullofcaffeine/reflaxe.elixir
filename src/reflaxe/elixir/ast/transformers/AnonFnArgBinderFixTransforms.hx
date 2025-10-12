package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AnonFnArgBinderFixTransforms
 *
 * WHAT
 * - Fix anonymous functions that bind underscore-prefixed args (e.g., _t) but
 *   body references the non-underscored variant (t). Renames binder to the
 *   referenced name to avoid undefined variable and underscore-usage warnings.
 *
 * WHY
 * - Some LiveView helpers and Enum.reduce/concat callbacks end up with `_x`
 *   binders while the body refers to `x`, causing mismatches and warnings.
 *
 * HOW
 * - For each EFn clause, collect body var names. For any PVar name starting
 *   with '_' where the body references its non-underscore variant and not the
 *   underscored one, rename binder to non-underscore name.
 *
 * EXAMPLES
 * Before:
 *   Enum.map(items, fn _t -> do_something(t) end)
 * After:
 *   Enum.map(items, fn t -> do_something(t) end)
 */
class AnonFnArgBinderFixTransforms {
    public static function fixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var used = collectUsedVars(cl.body);
                        var args = [];
                        for (a in cl.args) args.push(fixPattern(a, used));
                        newClauses.push({args: args, guard: cl.guard, body: cl.body});
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function collectUsedVars(node: ElixirAST): Map<String, Bool> {
        var used = new Map<String, Bool>();
        function visit(e: ElixirAST): Void {
            if (e == null || e.def == null) return;
            switch (e.def) {
                case EVar(name): used.set(name, true);
                case EBlock(stmts): for (s in stmts) visit(s);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case ECase(expr, clauses): visit(expr); for (c in clauses) { if (c.guard != null) visit(c.guard); visit(c.body); }
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(tgt2, _, args2): visit(tgt2); for (a2 in args2) visit(a2);
                case EList(els): for (el in els) visit(el);
                case ETuple(els): for (el in els) visit(el);
                case EMap(pairs): for (p in pairs) { visit(p.key); visit(p.value); }
                case EKeywordList(pairs): for (p in pairs) visit(p.value);
                case EStructUpdate(base, fields): visit(base); for (f in fields) visit(f.value);
                case EFn(clauses): for (cl in clauses) visit(cl.body);
                default:
            }
        }
        visit(node);
        return used;
    }

    static function fixPattern(p: EPattern, used: Map<String, Bool>): EPattern {
        return switch (p) {
            case PVar(name) if (name != null && name.length > 1 && name.charAt(0) == '_'):
                var trimmed = name.substr(1);
                if (used.exists(trimmed) && !used.exists(name)) PVar(trimmed) else PVar(name);
            case PVar(name): PVar(name);
            case PTuple(els): PTuple(els.map(e -> fixPattern(e, used)));
            case PList(els): PList(els.map(e -> fixPattern(e, used)));
            case PCons(h, t): PCons(fixPattern(h, used), fixPattern(t, used));
            case PMap(pairs): PMap(pairs.map(pa -> {key: pa.key, value: fixPattern(pa.value, used)}));
            case PStruct(m, fields): PStruct(m, fields.map(f -> {key: f.key, value: fixPattern(f.value, used)}));
            case PAlias(name, pat) if (name != null && name.length > 1 && name.charAt(0) == '_'):
                var trimmed = name.substr(1);
                if (used.exists(trimmed) && !used.exists(name)) PAlias(trimmed, fixPattern(pat, used)) else PAlias(name, fixPattern(pat, used));
            case PAlias(name, pat): PAlias(name, fixPattern(pat, used));
            case PPin(inner): PPin(fixPattern(inner, used));
            case PBinary(segs): PBinary(segs.map(s -> {pattern: fixPattern(s.pattern, used), size: s.size, type: s.type, modifiers: s.modifiers}));
            case PWildcard | PLiteral(_): p;
        }
    }
}

#end
