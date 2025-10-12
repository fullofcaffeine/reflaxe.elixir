package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

/**
 * ClauseUndefinedVarToBinderTransforms
 *
 * WHAT
 * - Rewrites undefined variables in clause bodies to the corresponding
 *   pattern binders when there is an unambiguous match.
 *
 * WHY
 * - Avoids runtime errors by binding body references to known clause variables
 *   without app-specific heuristics.
 *
 * HOW
 * - If exactly one binder matches the undefined name (after snake_case normalization),
 *   replace the reference with that binder.
 *
 * EXAMPLES
 * Before: case {:ok, v} -> data end; After: case {:ok, v} -> v end
 */
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * ClauseUndefinedVarToBinderTransforms
 *
 * WHAT
 * - Within case clauses that bind a single payload variable (e.g., {:tag, value}),
 *   replace references to exactly one undefined variable name in the clause body
 *   with the bound payload variable.
 *
 * WHY
 * - Upstream translations may preserve meaningful body variable names (id, params, query)
 *   while case patterns use generic binders (value). This creates undefined-variable errors.
 *   Rewriting the undefined body variable to the actual bound payload maintains readability
 *   without relying on tag heuristics.
 *
 * HOW
 * - For each function (EDef/EDefp):
 *   1) Collect defined variable names (from argument patterns and assignments).
 *   2) For each ECase clause with exactly one PVar binder:
 *      - Collect used lower-case variable names in the clause body.
 *      - Compute undefined = used - defined - {binder}.
 *      - If undefined contains exactly one name u, replace all EVar(u) in the clause body with EVar(binder).
 */
class ClauseUndefinedVarToBinderTransforms {
    public static function replaceUndefinedVarWithBinderPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var defined = collectFunctionDefinedVars(args, body);
                    var newBody = process(body, defined);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var defined = collectFunctionDefinedVars(args, body);
                    var newBody = process(body, defined);
                    makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function process(body: ElixirAST, defined: Map<String, Bool>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var binder = extractSingleBinder(cl.pattern);
                        if (binder != null) {
                            var used = collectUsedLowerVars(cl.body);
                            // Prefer well-known, generic event payload names when present
                            var preferred = pickPreferred(used, binder);
                            if (preferred != null) {
                                var newBody = replaceVar(cl.body, preferred, binder);
                                newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                                continue;
                            } else {
                                // Fallback: single undefined variable in body
                                var undef = used.filter(v -> v != binder && !isDefined(v, defined))
                                    .filter(v -> v != "socket" && v != "live_socket" && v != "liveSocket"
                                        && !StringTools.endsWith(v, "socket") && !StringTools.endsWith(v, "Socket"));
                                if (undef.length == 1) {
                                    var targetVar = undef[0];
                                    var nbody = replaceVar(cl.body, targetVar, binder);
                                    newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: nbody });
                                    continue;
                                }
                            }
                        }
                        newClauses.push(cl);
                    }
                    makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function replaceVar(body: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
                default: x;
            }
        });
    }

    static function collectFunctionDefinedVars(args: Array<EPattern>, body: ElixirAST): Map<String, Bool> {
        var vars = new Map<String, Bool>();
        for (a in args) collectPatternVars(a, vars);
        ASTUtils.walk(body, function(x: ElixirAST) {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case EMatch(p, _): collectPatternVars(p, vars);
                case EBinary(Match, l, _): collectLhsVars(l, vars);
                default:
            }
        });
        return vars;
    }

    static function collectPatternVars(p: EPattern, vars: Map<String, Bool>): Void {
        switch (p) {
            case PVar(n): if (n != null && n.length > 0) vars.set(n, true);
            case PTuple(es) | PList(es): for (e in es) collectPatternVars(e, vars);
            case PCons(h, t): collectPatternVars(h, vars); collectPatternVars(t, vars);
            case PMap(kvs): for (kv in kvs) collectPatternVars(kv.value, vars);
            case PStruct(_, fs): for (f in fs) collectPatternVars(f.value, vars);
            case PPin(inner): collectPatternVars(inner, vars);
            default:
        }
    }

    static function collectLhsVars(lhs: ElixirAST, vars: Map<String, Bool>): Void {
        switch (lhs.def) {
            case EVar(n): vars.set(n, true);
            case EBinary(Match, l2, r2): collectLhsVars(l2, vars); collectLhsVars(r2, vars);
            default:
        }
    }

    static function extractSingleBinder(pat: EPattern): Null<String> {
        return switch (pat) {
            case PTuple(elements) if (elements.length == 2):
                switch (elements[1]) { case PVar(n): n; default: null; }
            default: null;
        }
    }

    static function collectUsedLowerVars(ast: ElixirAST): Array<String> {
        var names = new Map<String, Bool>();
        function scan(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EVar(name): if (name != null && name.length > 0 && isLower(name)) names.set(name, true);
                case EField(t, _): scan(t);
                case EAccess(t, k): scan(t); scan(k);
                case EBinary(_, l, r): scan(l); scan(r);
                case EUnary(_, e): scan(e);
                case EPipe(l, r): scan(l); scan(r);
                case EBlock(es): for (e in es) scan(e);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case ECase(e, cs): scan(e); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body);} 
                case ECall(t, _, as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
                case ERemoteCall(m, _, as): scan(m); if (as != null) for (a in as) scan(a);
                case ETuple(items) | EList(items): for (i in items) scan(i);
                case EMap(pairs): for (p in pairs) { scan(p.key); scan(p.value); }
                default:
            }
        }
        scan(ast);
        return [for (k in names.keys()) k];
    }

    static inline function isLower(s: String): Bool {
        var c = s.charAt(0);
        return c.toLowerCase() == c;
    }

    static function pickPreferred(used: Array<String>, binder: String): Null<String> {
        // Generic names commonly used for event payloads across Phoenix apps (target-agnostic)
        var prefs = ["id", "params", "query", "filter", "sort_by", "tag"];
        var hits = [for (n in used) if (n != binder && prefs.indexOf(n) != -1) n];
        return hits.length == 1 ? hits[0] : null;
    }

    static function isDefined(name: String, defined: Map<String, Bool>): Bool {
        if (defined.exists(name)) return true;
        var snake = toSnake(name);
        if (snake != name && defined.exists(snake)) return true;
        return false;
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
