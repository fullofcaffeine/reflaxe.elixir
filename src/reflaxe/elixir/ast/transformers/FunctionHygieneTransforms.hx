package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FunctionHygieneTransforms
 *
 * WHAT
 * - Final-phase hygiene cleanups at function level:
 *   1) Simplify chained assignments when inner var is unused later in the block
 *      (outer = inner = expr) → (outer = expr)
 *   2) Drop top-level numeric sentinel literals (1/0/0.0) inside def/defp bodies
 *   3) Underscore unused function parameters in EDef/EDefp when not referenced in the body
 *
 * WHY
 * - Remove compiler artifacts that manifest as warnings in LiveView helpers and changeset code
 * - Achieve WAE=0 for the todo-app without app-coupled heuristics
 *
 * HOW
 * - Block-based pass for chained assignments with a forward usage scan
 * - Function-body pass to drop bare numeric literals at top level
 * - Parameter usage analysis to underscore unused params
 */
class FunctionHygieneTransforms {
    public static function blockAssignChainSimplifyPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    #if debug_hygiene
                    Sys.println('[BlockAssignChainSimplify] visiting def ' + name);
                    #end
                    var newBody = simplifyChainsInBody(body);
                    makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function simplifyChainsInBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out = [];
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    switch (s.def) {
                        case EBinary(Match, leftOuter, rhsOuter):
                            switch (rhsOuter.def) {
                                case EBinary(Match, leftInner, expr):
                                    var innerName: Null<String> = switch (leftInner.def) { case EVar(n): n; default: null; };
                                    var outerName: Null<String> = switch (leftOuter.def) { case EVar(n2): n2; default: null; };
                                    #if debug_hygiene
                                    Sys.println('[BlockAssignChainSimplify] chain detected outer=' + (outerName == null ? 'null' : outerName) + ', inner=' + (innerName == null ? 'null' : innerName));
                                    #end
                                    // Rule A: drop inner temp if not used later → outer = expr
                                    if (innerName != null && !usedLater(stmts, i + 1, innerName)) {
                                        #if debug_hygiene
                                        Sys.println('[BlockAssignChainSimplify] dropping inner temp ' + innerName);
                                        #end
                                        out.push(makeAST(EBinary(Match, leftOuter, expr)));
                                        continue;
                                    }
                                    // Rule B: drop outer temp if not used later → inner = expr
                                    if (outerName != null && !usedLater(stmts, i + 1, outerName)) {
                                        #if debug_hygiene
                                        Sys.println('[BlockAssignChainSimplify] dropping outer temp ' + outerName);
                                        #end
                                        out.push(makeAST(EBinary(Match, leftInner, expr)));
                                        continue;
                                    }
                                    out.push(s);
                                case EMatch(patInner, expr2):
                                    var innerName2: Null<String> = switch (patInner) { case PVar(n3): n3; default: null; };
                                    var outerName2: Null<String> = switch (leftOuter.def) { case EVar(n4): n4; default: null; };
                                    #if debug_hygiene
                                    Sys.println('[BlockAssignChainSimplify] chain (EMatch) detected outer=' + (outerName2 == null ? 'null' : outerName2) + ', inner=' + (innerName2 == null ? 'null' : innerName2));
                                    #end
                                    if (innerName2 != null && !usedLater(stmts, i + 1, innerName2)) {
                                        out.push(makeAST(EBinary(Match, leftOuter, expr2)));
                                        continue;
                                    }
                                    if (outerName2 != null && !usedLater(stmts, i + 1, outerName2)) {
                                        out.push(makeAST(EMatch(patInner, expr2)));
                                        continue;
                                    }
                                    out.push(s);
                                default:
                                    out.push(s);
                            }
                        default:
                            out.push(s);
                    }
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }

    static function usedLater(stmts: Array<ElixirAST>, startIdx: Int, name: String): Bool {
        for (j in startIdx...stmts.length) if (stmtUsesVar(stmts[j], name)) return true;
        return false;
    }

    static function stmtUsesVar(n: ElixirAST, name: String): Bool {
        var found = false;

        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
        }

        function walk(x: ElixirAST, inPattern: Bool): Void {
            if (x == null || found) return;
            switch (x.def) {
                case EVar(v):
                    // Count only expression-position vars, ignore pattern binders
                    if (!inPattern && v == name) { found = true; return; }
                case EBinary(Match, left, rhs):
                    // Do not descend into left (pattern); only inspect RHS
                    walk(rhs, false);
                case EMatch(pat, rhs2):
                    // Pattern match form: ignore pattern
                    walk(rhs2, false);
                case ERaw(code):
                    if (name != null && name.length > 0 && name.charAt(0) != '_') {
                        var start = 0;
                        while (!found) {
                            var i = code.indexOf(name, start);
                            if (i == -1) break;
                            var before = i > 0 ? code.substr(i - 1, 1) : null;
                            var afterIdx = i + name.length;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            var beforeIsIdent = isIdentChar(before);
                            var afterIsIdent = isIdentChar(after);
                            if (!beforeIsIdent && !afterIsIdent) { found = true; break; }
                            start = i + name.length;
                        }
                    }
                case EBlock(ss): for (s in ss) walk(s, false);
                case EDo(ss2): for (s in ss2) walk(s, false);
                case EIf(c,t,e): walk(c, false); walk(t, false); if (e != null) walk(e, false);
                case EBinary(_, l, r): walk(l, false); walk(r, false);
                case ECall(tgt, _, args): if (tgt != null) walk(tgt, false); for (a in args) walk(a, false);
                case ERemoteCall(tgt2, _, args2): walk(tgt2, false); for (a2 in args2) walk(a2, false);
                case ECase(expr, cs): walk(expr, false); for (c in cs) walk(c.body, false);
                default:
            }
        }
        walk(n, false);
        return found;
    }

    public static function functionTopLevelSentinelCleanupPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var newBody = dropTopLevelSentinels(body);
                    makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function dropTopLevelSentinels(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out = [];
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    var isLast = (i == stmts.length - 1);
                    switch (s.def) {
                        case EInteger(v) if ((v == 0 || v == 1) && !isLast):
                            // drop only when not the last statement
                        case EFloat(f) if (f == 0.0 && !isLast):
                            // drop only when not the last statement
                        default:
                            out.push(s);
                    }
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }

    public static function fnParamUnusedUnderscorePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var newArgs: Array<EPattern> = [];
                    for (a in args) newArgs.push(underscoreIfUnused(a, body));
                    makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function underscoreIfUnused(pat: EPattern, body: ElixirAST): EPattern {
        return switch (pat) {
            case PVar(n) if (!stmtUsesVar(body, n) && (n.length > 0 && n.charAt(0) != '_')): PVar('_' + n);
            default: pat;
        }
    }
}

#end
