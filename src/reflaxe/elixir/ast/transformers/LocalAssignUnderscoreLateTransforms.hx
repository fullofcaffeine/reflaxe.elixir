package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalAssignUnderscoreLateTransforms
 *
 * WHAT
 * - In block-like contexts (EBlock/EDo/EFn bodies), underscore local assignment targets
 *   when they are not referenced later in the same block. Also handles nested assignments
 *   inside `outer = (inner = expr)` by underscoring `inner` when unused.
 *
 * WHY
 * - Removes warnings for throwaway temps (e.g., g, g3) created by intermediate rewrites.
 */
/**
 * LocalAssignUnderscoreLateTransforms
 *
 * WHAT
 * - Late hygiene sweep that underscores local assignment targets not referenced later
 *   and collapses nested chains `outer = (inner = expr)` where safe.
 *
 * WHY
 * - Eliminates throwaway temps (g/g3/thisN) produced by intermediate rewrites that
 *   otherwise cause WAE. Collapsing nested chains produces cleaner, idiomatic code.
 *
 * HOW
 * - For EBlock/EDo/EFn bodies, scan each statement, detect nested matches, and either
 *   collapse or underscore unused binders. Variable usage checks look through common
 *   constructs to avoid false positives/negatives.
 */
class LocalAssignUnderscoreLateTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts): makeASTWithMeta(EBlock(processStmts(stmts)), n.metadata, n.pos);
                case EDo(stmts2): makeASTWithMeta(EDo(processStmts(stmts2)), n.metadata, n.pos);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var b = cl.body;
                        var nb = switch (b.def) {
                            case EBlock(ss): makeASTWithMeta(EBlock(processStmts(ss)), b.metadata, b.pos);
                            case EDo(ss2): makeASTWithMeta(EDo(processStmts(ss2)), b.metadata, b.pos);
                            default: b;
                        };
                        newClauses.push({ args: cl.args, guard: cl.guard, body: nb });
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * processStmts
     *
     * WHAT
     * - Processes a statement list, applying nested assign collapse and underscore
     *   of unused local assignment targets.
     */
    static function processStmts(stmts:Array<ElixirAST>): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        for (i in 0...stmts.length) {
            var s = stmts[i];
            switch (s.def) {
                case EBinary(Match, left, rhs):
                    // Nested: outer = (inner = expr) → underscore inner if unused later
                    var collapse = false;
                    var collapsedExpr:Null<ElixirAST> = null;
                    var newRhs = switch (rhs.def) {
                        case EBinary(Match, leftInner, expr):
                            var innerName:Null<String> = switch (leftInner.def) { case EVar(n): n; default: null; };
                            if (innerName != null && !usedLater(stmts, i + 1, innerName)) {
                                // Collapse nested: outer = (inner = expr) -> outer = expr
                                collapse = true;
                                collapsedExpr = expr;
                                rhs;
                            } else rhs;
                        default: rhs;
                    };
                    // Left var unused later → underscore
                    var leftName:Null<String> = switch (left.def) { case EVar(n): n; default: null; };
                    var newLeft = left;
                    if (leftName != null && !usedLater(stmts, i + 1, leftName)) {
                        newLeft = makeASTWithMeta(EVar('_' + leftName), left.metadata, left.pos);
                    }
                    if (collapse && collapsedExpr != null) {
                        #if debug_hygiene
                        Sys.println('[LocalAssignUnderscoreLate] collapsing nested assign into outer');
                        #end
                        out.push(makeASTWithMeta(EBinary(Match, newLeft, collapsedExpr), s.metadata, s.pos));
                    } else {
                        out.push(makeASTWithMeta(EBinary(Match, newLeft, newRhs), s.metadata, s.pos));
                    }
                case EMatch(pat, rhs):
                    var collapse2 = false;
                    var collapsedExpr2:Null<ElixirAST> = null;
                    var newRhs2 = switch (rhs.def) {
                        case EBinary(Match, leftInner2, expr2):
                            var innerName2:Null<String> = switch (leftInner2.def) { case EVar(n): n; default: null; };
                            if (innerName2 != null && !usedLater(stmts, i + 1, innerName2)) {
                                collapse2 = true; collapsedExpr2 = expr2; rhs;
                            } else rhs;
                        case EMatch(patInner2, expr3):
                            var innerName3:Null<String> = switch (patInner2) { case PVar(n3): n3; default: null; };
                            if (innerName3 != null && !usedLater(stmts, i + 1, innerName3)) {
                                collapse2 = true; collapsedExpr2 = expr3; rhs;
                            } else rhs;
                        default: rhs;
                    };
                    var leftName2:Null<String> = switch (pat) { case PVar(nm): nm; default: null; };
                    var newPat = pat;
                    if (leftName2 != null && !usedLater(stmts, i + 1, leftName2) && leftName2.charAt(0) != '_') {
                        newPat = PVar('_' + leftName2);
                    }
                    if (collapse2 && collapsedExpr2 != null) {
                        out.push(makeASTWithMeta(EMatch(newPat, collapsedExpr2), s.metadata, s.pos));
                    } else {
                        out.push(makeASTWithMeta(EMatch(newPat, newRhs2), s.metadata, s.pos));
                    }
                default:
                    out.push(s);
            }
        }
        return out;
    }

    static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (j in start...stmts.length) if (stmtUsesVar(stmts[j], name)) return true; return false;
    }

    /**
     * stmtUsesVar
     *
     * WHAT
     * - Determines whether `name` is used in `n` (expression position), ignoring
     *   pattern binders but traversing typical nested forms.
     */
    static function stmtUsesVar(n:ElixirAST, name:String):Bool {
        var found = false;
        function walk(x:ElixirAST, inPattern:Bool):Void {
            if (x == null || found) return;
            switch (x.def) {
                case EVar(v) if (!inPattern && v == name): found = true;
                case EBinary(Match, left, rhs): walk(rhs, false);
                case EMatch(pat, rhs2): walk(rhs2, false);
                case EBlock(ss): for (s in ss) walk(s, false);
                case EDo(ss2): for (s in ss2) walk(s, false);
                case EIf(c,t,e): walk(c, false); walk(t, false); if (e != null) walk(e, false);
                case EBinary(_, l, r): walk(l, false); walk(r, false);
                case ECall(tgt, _, args): if (tgt != null) walk(tgt, false); for (a in args) walk(a, false);
                case ERemoteCall(tgt2, _, args2): walk(tgt2, false); for (a2 in args2) walk(a2, false);
                case ECase(expr, cs): walk(expr, false); for (c in cs) walk(c.body, false);
                case EString(str):
                    var i2 = 0;
                    while (!found && str != null && i2 < str.length) {
                        var idx2 = str.indexOf("#{", i2);
                        if (idx2 == -1) break;
                        var j2 = str.indexOf("}", idx2 + 2);
                        if (j2 == -1) break;
                        var inner = str.substr(idx2 + 2, j2 - (idx2 + 2));
                        if (inner.indexOf(name) != -1) { found = true; break; }
                        i2 = j2 + 1;
                    }
                case ETuple(elems): for (e in elems) walk(e, false);
                case EKeywordList(pairs): for (p in pairs) walk(p.value, false);
                case EStructUpdate(base, fields): walk(base, false); for (f in fields) walk(f.value, false);
                case EField(obj, _): walk(obj, false);
                case EAccess(tgt3, key): walk(tgt3, false); walk(key, false);
                default:
            }
        }
        walk(n, false);
        return found;
    }
}

#end
