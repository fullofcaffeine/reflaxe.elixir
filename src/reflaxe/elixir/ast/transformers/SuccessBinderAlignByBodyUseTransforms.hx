package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * SuccessBinderAlignByBodyUseTransforms
 *
 * WHAT
 * - In `case` clauses shaped as `{:ok, <binder>}`, align the binder name to the
 *   single undefined variable actually used in the clause body. This produces:
 *     case Repo.update(changeset) do
 *       {:ok, _updated_todo} -> broadcast(updated_todo)
 *     end
 *   →
 *     case Repo.update(changeset) do
 *       {:ok, updated_todo} -> broadcast(updated_todo)
 *     end
 *
 * WHY
 * - Earlier hygiene may underscore binders, while the clause body retains the meaningful
 *   variable name. This creates undefined-variable errors. When the body clearly uses a
 *   single undefined local, the intent is unambiguous: that name should be the binder.
 * - This pass is usage-driven and shape-based (no app-specific heuristics), matching our
 *   transformer discipline rules.
 *
 * HOW
 * - Scope: only `ECase` clauses whose pattern is a 2-tuple with first element `:ok` and
 *   second element `PVar` (binder). Operates within a single clause.
 * - Steps per clause:
 *   1) Collect function-level declared names (params, prior assignments) and clause-local
 *      declared names (pattern binds, LHS of matches inside the clause body).
 *   2) Collect all simple variable names used in the clause body.
 *   3) Compute `undefined = used \ declared \ {binder}` filtering out common env like `socket`.
 *   4) If `undefined.length == 1`, rename the binder in the pattern to that undefined name and
 *      rename any occurrences of the old binder in the clause body to the new name.
 * - Runs very late (absolute) to avoid being undone by subsequent hygiene.
 *
 * EXAMPLES
 * Haxe:
 *   switch (Repo.update(changeset)) {
 *     case Ok(updatedTodo):
 *       broadcast(updatedTodo);
 *     case Error(e):
 *   }
 * Elixir (before):
 *   case Repo.update(changeset) do
 *     {:ok, _updated_todo} -> broadcast(updated_todo)
 *     {:error, e} -> :error
 *   end
 * Elixir (after):
 *   case Repo.update(changeset) do
 *     {:ok, updated_todo} -> broadcast(updated_todo)
 *     {:error, e} -> :error
 *   end
 */
class SuccessBinderAlignByBodyUseTransforms {
    public static function alignPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var fnDeclared = collectFunctionDefinedVars(args, body);
                    var newBody = process(body, fnDeclared);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var fnDeclared2 = collectFunctionDefinedVars(args, body);
                    var newBody2 = process(body, fnDeclared2);
                    makeASTWithMeta(EDefp(name, args, guards, newBody2), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function process(body: ElixirAST, fnDeclared: Map<String,Bool>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var okBinder = extractOkBinder(cl.pattern);
                        if (okBinder != null) {
                            // Respect canonical payload locking: keep {:ok, _value} + aliases intact
                            var locked = false;
                            try { locked = untyped (cl.body != null && cl.body.metadata != null && (cl.body.metadata.lockPayloadBinder == true)); } catch (e:Dynamic) {}
                            if (okBinder == "_value" || locked) { newClauses.push(cl); continue; }
                            // Collect declared names inside clause body (pattern LHS and matches)
                            var clauseDeclared: Map<String,Bool> = new Map();
                            collectPatternDecls(cl.pattern, clauseDeclared);
                            collectLhsDeclsInBody(cl.body, clauseDeclared);
                            // Merge function-level declared (params + prior LHS) to avoid renaming to params
                            if (fnDeclared != null) for (k in fnDeclared.keys()) clauseDeclared.set(k, true);
                            // Collect used names in clause body
                            var used = collectUsedNames(cl.body);
                            #if (sys && debug_ast_transformer) {
                                var declArr = [for (k in clauseDeclared.keys()) k];
                                var usedArr = [for (k in used.keys()) k];
                                // DEBUG: Sys.println('[SuccessBinderAlign] declared=' + declArr.join(',') + ' used=' + usedArr.join(','));
                            } #end
                            // Find exactly one undefined, excluding env names
                            var undef = [];
                            for (u in used.keys()) if (!clauseDeclared.exists(u) && u != okBinder && allowUndefined(u)) undef.push(u);
                            if (undef.length == 1) {
                                var newName = undef[0];
                                // Guard: never rename binder to a reserved env name
                                if (!allowUndefined(newName)) {
                                    newClauses.push(cl);
                                    continue;
                                }
                                // Rewrite pattern binder to newName
                                var newPattern = rewriteOkBinder(cl.pattern, newName);
                                // Rewrite old binder references in body to newName
                                // Only rewrite the binder in the pattern. Do NOT replace the old
                                // binder name inside the body so that any references to `socket`
                                // (or other outer variables) correctly refer to the outer scope
                                // once the shadowing binder is renamed.
                                newClauses.push({ pattern: newPattern, guard: cl.guard, body: cl.body });
                                continue;
                            }
                            // Fallback: if multiple undefineds, choose the most frequently used in the body
                            if (undef.length >= 1) {
                                var freq = new haxe.ds.StringMap<Int>();
                                for (u in undef) freq.set(u, 0);
                                ASTUtils.walk(cl.body, function(w: ElixirAST) {
                                    switch (w.def) { case EVar(nm) if (freq.exists(nm)): freq.set(nm, freq.get(nm) + 1); default: }
                                });
                                var best:Null<String> = null; var bestCount = -1;
                                for (u in undef) {
                                    var c = freq.exists(u) ? freq.get(u) : 0;
                                    if (c > bestCount) { bestCount = c; best = u; }
                                }
                                if (best != null && allowUndefined(best)) {
                                    var newPat2 = rewriteOkBinder(cl.pattern, best);
                                    newClauses.push({ pattern: newPat2, guard: cl.guard, body: cl.body });
                                    continue;
                                }
                            }
                            // If no clear undefineds, keep binder as-is
                        }
                        newClauses.push(cl);
                    }
                    makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function allowUndefined(name: String): Bool {
        if (name == null || name.length == 0) return false;
        // Exclude common environment names we never want to rebind to binder
        if (name == "socket" || name == "live_socket" || name == "liveSocket") return false;
        // Must be lowercase-starting simple name
        return isLower(name);
    }

    static function collectFunctionDefinedVars(args: Array<EPattern>, body: ElixirAST): Map<String, Bool> {
        var vars = new Map<String, Bool>();
        for (a in args) collectPatternDecls(a, vars);
        ASTUtils.walk(body, function(x: ElixirAST) {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case EMatch(p, _): collectPatternDecls(p, vars);
                case EBinary(Match, l, _): collectLhsDecls(l, vars);
                default:
            }
        });
        return vars;
    }

    static function collectLhsDeclsInBody(body: ElixirAST, vars: Map<String,Bool>): Void {
        ASTUtils.walk(body, function(x: ElixirAST) {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case EMatch(p, _): collectPatternDecls(p, vars);
                case EBinary(Match, l, _): collectLhsDecls(l, vars);
                case ECase(_, cs): for (c in cs) collectPatternDecls(c.pattern, vars);
                default:
            }
        });
    }

    static function collectPatternDecls(p: EPattern, vars: Map<String,Bool>): Void {
        switch (p) {
            case PVar(n): if (n != null && n.length > 0) vars.set(n, true);
            case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, vars);
            case PCons(h, t): collectPatternDecls(h, vars); collectPatternDecls(t, vars);
            case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, vars);
            case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, vars);
            case PPin(inner): collectPatternDecls(inner, vars);
            default:
        }
    }

    static function collectLhsDecls(lhs: ElixirAST, vars: Map<String,Bool>): Void {
        switch (lhs.def) {
            case EVar(n): vars.set(n, true);
            case EBinary(Match, l2, r2): collectLhsDecls(l2, vars); collectLhsDecls(r2, vars);
            default:
        }
    }

    static function collectUsedNames(ast: ElixirAST): Map<String,Bool> {
        var names = new Map<String,Bool>();
        ASTUtils.walk(ast, function(x: ElixirAST) {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case EVar(v): names.set(v, true);
                default:
            }
        });
        return names;
    }

    static function extractOkBinder(p: EPattern): Null<String> {
        return switch (p) {
            case PTuple(elements) if (elements.length == 2):
                switch (elements[0]) {
                    case PLiteral(l) if (isOkAtom(l)):
                        switch (elements[1]) { case PVar(n): n; default: null; }
                    default: null;
                }
            default: null;
        }
    }

    static inline function isOkAtom(ast: ElixirAST): Bool {
        return switch (ast.def) { case EAtom(v): v == ":ok" || v == "ok"; default: false; };
    }

    static function rewriteOkBinder(p: EPattern, newName: String): EPattern {
        return switch (p) {
            case PTuple(es) if (es.length == 2):
                switch (es[0]) {
                    case PLiteral(l) if (isOkAtom(l)):
                        switch (es[1]) {
                            case PVar(_): PTuple([es[0], PVar(newName)]);
                            default: p;
                        }
                    default: p;
                }
            default: p;
        }
    }

    static function replaceVar(body: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(n) if (n == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
                default: x;
            }
        });
    }

    static inline function isLower(s: String): Bool {
        if (s == null || s.length == 0) return false;
        var c = s.charAt(0);
        return c.toLowerCase() == c;
    }

    static inline function cloneMap<T>(m: Map<String,T>): Map<String,T> {
        var n = new Map<String,T>();
        if (m == null) return n;
        for (k in m.keys()) n.set(k, m.get(k));
        return n;
    }
}

#end
