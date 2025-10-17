package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.analyzers.ValueShapeAnalyzer;

/**
 * SingleBinderByUsageTransforms
 *
 * WHAT
 * - Renames the single payload binder in case clauses (e.g., {:tag, value}) to match the
 *   variable actually used in the clause body when that used variable is otherwise undefined
 *   in the enclosing function scope.
 *
 * WHY
 * - Avoid undefined-variable errors and remove reliance on tag→name heuristics. Bodies often
 *   reference meaningful names (e.g., `todo`, `id`, `params`) while the pattern binds a generic
 *   variable (e.g., `value`). This pass aligns the binder to the actual usage without coupling
 *   to app-specific tags or domains.
 *
 * HOW
 * - For each function (EDef/EDefp):
 *   1) Collect function-scope defined variables (from arg patterns and assignments).
 *   2) Walk all ECase nodes. For each clause with exactly one PVar binder:
 *      - Compute used lower-case variables in the clause body.
 *      - Filter to those not defined in the function scope and not equal to the binder.
 *      - If exactly one candidate remains, rename the binder to that candidate.
 *
 * EXAMPLES
 * Haxe:
 *   switch (msg) {
 *     case TodoCreated(todo): addTodoToList(todo, socket);
 *     case TodoDeleted(id): removeTodoFromList(id, socket);
 *   }
 *
 * Elixir (before):
 *   case msg do
 *     {:todo_created, value} -> add_todo_to_list(todo, socket)  # 'todo' undefined
 *   end
 *
 * Elixir (after):
 *   case msg do
 *     {:todo_created, todo} -> add_todo_to_list(todo, socket)
 *   end
 */
class SingleBinderByUsageTransforms {
    public static function renameSingleBinderByBodyUsagePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var defined = collectFunctionDefinedVars(args, body);
                    var newBody = rewriteCases(body, defined);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var defined = collectFunctionDefinedVars(args, body);
                    var newBody = rewriteCases(body, defined);
                    makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function rewriteCases(body: ElixirAST, defined: Map<String, Bool>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var binder = extractSingleBinder(cl.pattern);
                        if (binder != null) {
                            var used = collectUsedLowerVars(cl.body);
                            // Generic: rename binder to the unique undefined lower-case var used in body
                            var cands = used.filter(v -> v != binder && !isDefinedName(v, defined));
                            // Special allowance: if the body uses `id` or `_id`, prefer unifying the binder to `id`
                            // even when `id` is already defined at function scope. This avoids later misalignments
                            // where calls inside the clause are rewritten to the binder name.
                            var preferId = false;
                            if (!used.remove("id")) {
                                // used.remove returns false when key not present; we need presence check differently
                            }
                            // Presence check for id/_id
                            var usedHasId = false; var usedHas_Uid = false;
                            for (u in used) {
                                if (u == "id") usedHasId = true;
                                else if (u == "_id") usedHas_Uid = true;
                            }
                            #if sys
                            var usedListDbg = [];
                            for (k in used) usedListDbg.push(k);
                            Sys.println('[SingleBinderByUsage] binder=' + binder + ' used=' + usedListDbg.join(',') + ' cands=' + cands.join(',') + ' hasId=' + usedHasId + ' has_Uid=' + usedHas_Uid);
                            #end
                            var newName: Null<String> = null;
                            if (cands.length == 1) {
                                newName = cands[0];
                            } else if (cands.length == 0 && binder != "id" && (usedHasId || usedHas_Uid)) {
                                newName = "id";
                            }
                            // Shape guard: avoid binding a struct-shaped payload to an id-like name
                            if (newName != null && newName != binder) {
                                var shapes = ValueShapeAnalyzer.classify(cl.body);
                                var newIsIdLike = ValueShapeAnalyzer.isIdLike(newName, shapes);
                                // binder looks struct-like if used as field receiver in body
                                var binderLooksStruct = ValueShapeAnalyzer.isStructLike(binder, shapes);
                                if (newIsIdLike && binderLooksStruct) {
                                    // Skip renaming: binding struct to `id` would be misleading and propagate incompatible naming
                                    newName = null;
                                }
                            }
                            if (newName != null && newName != binder) {
                                #if debug_single_binder
                                trace('[SingleBinderByUsage] Renaming binder ' + binder + ' -> ' + newName);
                                #end
                                var renamed = tryRenameSingleBinder(cl.pattern, newName);
                                if (renamed != null) {
                                    newClauses.push({ pattern: renamed, guard: cl.guard, body: cl.body });
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

    static function collectFunctionDefinedVars(args: Array<EPattern>, body: ElixirAST): Map<String, Bool> {
        var vars = new Map<String, Bool>();
        // From function arguments
        for (a in args) collectPatternVars(a, vars);
        // From function body declarations (patterns and simple matches)
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
            case EBinary(Match, l2, r2):
                collectLhsVars(l2, vars);
                collectLhsVars(r2, vars);
            default:
        }
    }

    static function extractSingleBinder(pat: EPattern): Null<String> {
        return switch (pat) {
            case PTuple(elements) if (elements.length == 2):
                switch (elements[1]) {
                    case PVar(n): n;
                    default: null;
                }
            default: null;
        }
    }

    static function tryRenameSingleBinder(pat: EPattern, newName: String): Null<EPattern> {
        return switch (pat) {
            case PTuple(elements) if (elements.length == 2):
                switch (elements[1]) {
                    case PVar(oldName) if (oldName != newName):
                        PTuple([elements[0], PVar(newName)]);
                    default: null;
                }
            default: null;
        }
    }

    static function collectUsedLowerVars(ast: ElixirAST): Array<String> {
        var names = new Map<String, Bool>();
        function scan(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EVar(name):
                    if (name != null && name.length > 0 && isLower(name)) names.set(name, true);
                case EString(value):
                    // Extract #{var} placeholders in interpolated strings
                    if (value != null && value.length > 0) {
                        var re = new EReg("\\#\\{([a-z_][a-zA-Z0-9_]*)\\}", "g");
                        var pos = 0;
                        while (re.matchSub(value, pos)) {
                            var v = re.matched(1);
                            if (v != null && isLower(v)) names.set(v, true);
                            var mEnd = re.matchedPos().pos + re.matchedPos().len;
                            pos = mEnd;
                        }
                    }
                case EField(target, _): scan(target);
                case EAccess(target, key): scan(target); scan(key);
                case EBinary(_, left, right): scan(left); scan(right);
                case EUnary(_, expr): scan(expr);
                case EPipe(left, right): scan(left); scan(right);
                case EBlock(exprs): for (e in exprs) scan(e);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case ECase(expr, clauses):
                    scan(expr); for (c in clauses) { if (c.guard != null) scan(c.guard); scan(c.body);} 
                case ECall(target, _, args): if (target != null) scan(target); if (args != null) for (a in args) scan(a);
                case ERemoteCall(mod, _, args): scan(mod); if (args != null) for (a in args) scan(a);
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

    static function isDefinedName(name: String, defined: Map<String, Bool>): Bool {
        if (defined.exists(name)) return true;
        var snake = toSnake(name);
        if (snake != name && defined.exists(snake)) return true;
        return false;
    }
}

#end
