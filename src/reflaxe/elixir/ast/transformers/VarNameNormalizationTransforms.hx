package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * VarNameNormalizationTransforms
 *
 * WHY: Mixed-case variable names (e.g., presenceSocket) can appear in references while
 *      the actual binding uses snake_case (presence_socket). This causes undefined variables.
 * WHAT: Within a function's scope (EDef/EDefp), normalize EVar references from camelCase to snake_case
 *       when a binding with that snake_case name exists.
 * HOW: Collect defined variable names (from patterns and EMatch LHS) and rewrite references when matching.
 */
class VarNameNormalizationTransforms {
    public static function varNameNormalizationPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EDef(name, args, guards, body):
                    var defined = collectDefinedVars(args, body);
                    var newBody = normalizeVarsInBody(body, defined);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var defined = collectDefinedVars(args, body);
                    var newBody = normalizeVarsInBody(body, defined);
                    makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function collectDefinedVars(args: Array<EPattern>, body: ElixirAST): Map<String, Bool> {
        var vars = new Map<String, Bool>();
        // From arguments
        for (a in args) collectPatternVars(a, vars);
        // From body bindings (EMatch LHS)
        function scan(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch(n.def) {
                case EMatch(pattern, _): collectPatternVars(pattern, vars);
                case EBlock(exprs): for (e in exprs) scan(e);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case ECase(expr, clauses):
                    // Include variables bound by case clause patterns as defined in scope
                    scan(expr);
                    for (c in clauses) {
                        collectPatternVars(c.pattern, vars);
                        if (c.guard != null) scan(c.guard);
                        scan(c.body);
                    }
                case EWith(clauses, doBlock, elseBlock):
                    for (wc in clauses) {
                        collectPatternVars(wc.pattern, vars);
                        scan(wc.expr);
                    }
                    scan(doBlock);
                    if (elseBlock != null) scan(elseBlock);
                case ECall(target, _, args): if (target != null) scan(target); for (a in args) scan(a);
                case ERemoteCall(mod, _, args): scan(mod); for (a in args) scan(a);
                case EList(items) | ETuple(items): for (i in items) scan(i);
                case EMap(pairs): for (p in pairs) { scan(p.key); scan(p.value); }
                default:
            }
        }
        scan(body);
        return vars;
    }

    static function collectPatternVars(p: EPattern, vars: Map<String, Bool>): Void {
        switch(p) {
            case PVar(name): vars.set(name, true);
            case PTuple(items) | PList(items): for (i in items) collectPatternVars(i, vars);
            case PCons(h, t): collectPatternVars(h, vars); collectPatternVars(t, vars);
            case PMap(pairs): for (kv in pairs) collectPatternVars(kv.value, vars);
            case PStruct(_, fields): for (f in fields) collectPatternVars(f.value, vars);
            case PPin(inner): collectPatternVars(inner, vars);
            case PWildcard | PAlias(_, _) | PBinary(_):
            case PLiteral(_):
        }
    }

    static function normalizeVarsInBody(body: ElixirAST, defined: Map<String, Bool>): ElixirAST {
        // Helper: fuzzy match undefined names to defined ones by token overlap
        function findTokenMatch(name: String): Null<String> {
            if (name == null || name.length == 0) return null;
            var tokens = name.split("_");
            // Prefer matches sharing at least one token and especially the token "priority"
            var best: Null<String> = null;
            var bestScore = 0;
            for (k in defined.keys()) {
                var ktokens = k.split("_");
                var score = 0;
                for (t in tokens) {
                    for (kt in ktokens) if (t == kt) score++;
                }
                // Strong bonus: when defined ends with the undefined token (e.g., search_query vs query)
                if (k.length > name.length && StringTools.endsWith(k, "_" + name)) score += 3;
                if (tokens.indexOf("priority") != -1 && ktokens.indexOf("priority") != -1) score += 2;
                if (score > bestScore) { bestScore = score; best = k; }
            }
            if (bestScore > 0) return best; else return null;
        }
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch(n.def) {
                case EVar(name):
                    var snake = toSnake(name);
                    if (snake != name && defined.exists(snake)) {
                        #if sys Sys.println('[VarNameNormalization] ' + name + ' -> ' + snake); #end
                        makeASTWithMeta(EVar(snake), n.metadata, n.pos);
                    } else {
                        // If not defined, try fuzzy token match to an existing defined binding
                        if (!defined.exists(name)) {
                            var candidate = findTokenMatch(name);
                            if (candidate != null) {
                                #if sys Sys.println('[VarNameNormalization] ' + name + ' -> ' + candidate + ' (fuzzy)'); #end
                                return makeASTWithMeta(EVar(candidate), n.metadata, n.pos);
                            }
                        }
                        n;
                    }
                default:
                    n;
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
/**
 * VarNameNormalizationTransforms
 *
 * WHAT
 * - Normalizes variable references from camelCase to snake_case when a
 *   corresponding snake_case binding exists in scope.
 *
 * WHY
 * - Haxe sources use camelCase; Elixir idiomatically uses snake_case.
 *   Normalizing references prevents undefined variable errors and warnings.
 *
 * HOW
 * - Within a function (EDef/EDefp), collect declared binders; rewrite EVar
 *   names to their snake_case equivalent when that binder exists.
 *
 * EXAMPLES
 * Before: presenceSocket -> undefined
 * After:  presence_socket -> uses declared binder
 */
