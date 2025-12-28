package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import haxe.ds.StringMap;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ShadowedInitAssignPruneTransforms
 *
 * WHAT
 * - Drops trivial initializer assignments in a block when they are overwritten later
 *   at the same block level without being read in between.
 *
 * WHY
 * - Haxe commonly declares locals without initialization and assigns them later in control flow:
 *     var median: Float;
 *     if (cond) median = a else median = b;
 *   The compiler often emits an initializer like `median = nil` (or an empty map) to satisfy
 *   Elixir binding rules. When the variable is then assigned unconditionally later, that
 *   initializer becomes a dead store and triggers --warnings-as-errors:
 *     warning: variable "median" is unused
 *
 * HOW
 * - In each EBlock/EDo statement list, track assignments of the form `name = <literal>`
 *   where <literal> is side-effect-free (nil, literals, empty list/map, and nested literals).
 * - If `name` is not referenced by any statement before a subsequent top-level assignment to `name`,
 *   prune the earlier initializer.
 *
 * EXAMPLES
 * Before:
 *   median = nil
 *   mid = trunc(length(sorted) / 2)
 *   median = if cond do a else b end
 * After:
 *   mid = trunc(length(sorted) / 2)
 *   median = if cond do a else b end
 */
class ShadowedInitAssignPruneTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    makeASTWithMeta(EBlock(pruneStatements(stmts)), n.metadata, n.pos);
                case EDo(stmts):
                    makeASTWithMeta(EDo(pruneStatements(stmts)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function pruneStatements(stmts: Array<ElixirAST>): Array<ElixirAST> {
        if (stmts == null || stmts.length == 0) return stmts;

        var out: Array<Null<ElixirAST>> = [];
        var pendingInit = new StringMap<Int>(); // name -> index in out

        for (stmt in stmts) {
            // Any read of a pending var commits its initializer (we must keep it).
            for (name in pendingInit.keys()) {
                if (statementReadsName(stmt, name)) {
                    pendingInit.remove(name);
                }
            }

            var assignedName = assignedVarName(stmt);
            if (assignedName != null) {
                // If this assignment reads the previous binding, treat as a use and keep the initializer.
                if (statementReadsName(stmt, assignedName)) {
                    pendingInit.remove(assignedName);
                } else if (pendingInit.exists(assignedName)) {
                    var idx = pendingInit.get(assignedName);
                    if (idx != null && idx >= 0 && idx < out.length) out[idx] = null;
                    pendingInit.remove(assignedName);
                } else {
                    pendingInit.remove(assignedName);
                }
            }

            var outIndex = out.length;
            out.push(stmt);

            // Record a new initializer candidate.
            if (assignedName != null && isPrunableInitializer(stmt, assignedName) && !pendingInit.exists(assignedName)) {
                pendingInit.set(assignedName, outIndex);
            }
        }

        // Any remaining pending initializer was never read nor overwritten; drop it to avoid WAE warnings.
        for (name in pendingInit.keys()) {
            var idx = pendingInit.get(name);
            if (idx != null && idx >= 0 && idx < out.length) out[idx] = null;
        }

        var compact: Array<ElixirAST> = [];
        for (s in out) if (s != null) compact.push(s);
        return compact;
    }

    static function assignedVarName(stmt: ElixirAST): Null<String> {
        if (stmt == null || stmt.def == null) return null;
        return switch (stmt.def) {
            case EMatch(PVar(name), _):
                name;
            case EBinary(Match, left, _):
                switch (left.def) {
                    case EVar(name): name;
                    case EParen(inner):
                        switch (inner.def) { case EVar(name2): name2; default: null; }
                    default:
                        null;
                }
            default:
                null;
        };
    }

    static function isPrunableInitializer(stmt: ElixirAST, name: String): Bool {
        if (name == null || name == "_" || StringTools.startsWith(name, "_")) return false;
        var rhs = switch (stmt.def) {
            case EMatch(_, value): value;
            case EBinary(Match, _, value2): value2;
            default: null;
        };
        return rhs != null && isLiteral(rhs);
    }

    static function isLiteral(expr: ElixirAST): Bool {
        if (expr == null || expr.def == null) return false;
        return switch (expr.def) {
            case ENil | EBoolean(_) | EInteger(_) | EFloat(_) | EString(_) | EAtom(_):
                true;
            case EList(els):
                for (e in els) if (!isLiteral(e)) return false;
                true;
            case ETuple(els):
                for (e in els) if (!isLiteral(e)) return false;
                true;
            case EMap(pairs):
                for (p in pairs) {
                    if (!isLiteral(p.key)) return false;
                    if (!isLiteral(p.value)) return false;
                }
                true;
            case EKeywordList(pairs):
                for (p in pairs) if (!isLiteral(p.value)) return false;
                true;
            case EParen(inner):
                isLiteral(inner);
            default:
                false;
        };
    }

    static function statementReadsName(stmt: ElixirAST, name: String): Bool {
        if (stmt == null || stmt.def == null) return false;
        return switch (stmt.def) {
            // Do not treat assignment LHS as a "read" of the name.
            case EBinary(Match, _l, r):
                exprReadsName(r, name);
            case EMatch(_pat, r2):
                exprReadsName(r2, name);
            default:
                exprReadsName(stmt, name);
        };
    }

    static function exprReadsName(expr: ElixirAST, name: String): Bool {
        var found = false;

        function visit(e: ElixirAST): Void {
            if (found || e == null || e.def == null) return;
            switch (e.def) {
                case EVar(n) if (n == name):
                    found = true;
                case ERaw(code):
                    // Conservative: avoid pruning when the raw block may reference the name.
                    if (code != null && code.indexOf(name) != -1) found = true;
                case EBlock(stmts):
                    for (s in stmts) visit(s);
                case EDo(stmts2):
                    for (s2 in stmts2) visit(s2);
                case EIf(c, t, el):
                    visit(c); visit(t); if (el != null) visit(el);
                case ECond(clauses):
                    for (cl in clauses) {
                        visit(cl.condition);
                        visit(cl.body);
                    }
                case ECase(subject, clauses):
                    visit(subject);
                    for (cl in clauses) {
                        if (cl.guard != null) visit(cl.guard);
                        visit(cl.body);
                    }
                case EBinary(_, l, r):
                    visit(l); visit(r);
                case EUnary(_, inner):
                    visit(inner);
                case EMatch(_, rhs):
                    visit(rhs);
                case EPipe(l2, r2):
                    visit(l2); visit(r2);
                case ECall(tgt, _, args):
                    if (tgt != null) visit(tgt);
                    for (a in args) visit(a);
                case ERemoteCall(mod, _, args2):
                    visit(mod);
                    for (a2 in args2) visit(a2);
                case EList(els):
                    for (el in els) visit(el);
                case ETuple(els2):
                    for (el2 in els2) visit(el2);
                case EMap(pairs):
                    for (p in pairs) { visit(p.key); visit(p.value); }
                case EKeywordList(pairs):
                    for (p in pairs) visit(p.value);
                case EStructUpdate(base, fields):
                    visit(base);
                    for (f in fields) visit(f.value);
                case EField(t, _):
                    visit(t);
                case EAccess(t2, k):
                    visit(t2); visit(k);
                case ERange(a, b, _, step):
                    visit(a); visit(b); if (step != null) visit(step);
                case EFn(clauses):
                    for (cl in clauses) visit(cl.body);
                case EParen(inner2):
                    visit(inner2);
                default:
            }
        }

        visit(expr);
        return found;
    }
}

#end
