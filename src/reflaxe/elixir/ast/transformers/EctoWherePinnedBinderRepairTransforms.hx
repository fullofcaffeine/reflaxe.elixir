package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoWherePinnedBinderRepairTransforms
 *
 * WHAT
 * - When a function contains a wildcard literal assignment (`_ = "..."`) followed by
 *   an Ecto where/2 condition with a pinned variable `^(name)`, promote the last
 *   wildcard literal assignment before the where to `name = "..."` if `name` is
 *   not already declared by that point.
 *
 * WHY
 * - Late hygiene may convert an intended binder into a wildcard even though the
 *   value is used later as a pinned where argument (typed_query_basic case). This
 *   targeted repair preserves idiomatic usage while remaining shape-based.
 *
 * HOW
 * - For each def/defp body (EBlock/EDo), scan statements left-to-right, tracking:
 *   - The last seen wildcard literal assignment index
 *   - A set of declared names observed so far
 * - On encountering a where/2 whose condition contains EPin(EVar(name)), and when
 *   `name` is not declared yet and a prior wildcard-literal exists, rewrite that
 *   earlier wildcard to bind `name` instead.
 */
class EctoWherePinnedBinderRepairTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, repairBody(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, repairBody(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function repairBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts): makeASTWithMeta(EBlock(repairStmts(stmts)), body.metadata, body.pos);
            case EDo(stmts): makeASTWithMeta(EDo(repairStmts(stmts)), body.metadata, body.pos);
            default: body;
        }
    }

    static function isLiteral(e: ElixirAST): Bool {
        return switch (e.def) {
            case EString(_) | EInteger(_) | EFloat(_) | EBoolean(_) | EAtom(_) | EList(_) | EMap(_) | ETuple(_): true;
            default: false;
        };
    }

    static function extractPinnedName(n: ElixirAST): Null<String> {
        var found:Null<String> = null;
        ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
            if (found != null) return x;
            switch (x.def) {
                case EPin(inner):
                    switch (inner.def) { case EVar(v): found = v; default: }
                case ERaw(code) if (code != null):
                    // Extract first ^(name) occurrence conservatively
                    var i = 0;
                    while (i < code.length && found == null) {
                        var idx = code.indexOf("^(", i);
                        if (idx == -1) break;
                        var j = code.indexOf(")", idx + 2);
                        if (j == -1) break;
                        var candidate = code.substring(idx + 2, j);
                        if (~/^[A-Za-z_][A-Za-z0-9_]*$/.match(candidate)) found = candidate;
                        i = j + 1;
                    }
                default:
            }
            return x;
        });
        return found;
    }

    static function findPinnedInnerVar(n: ElixirAST): Null<ElixirAST> {
        var found:Null<ElixirAST> = null;
        ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
            if (found != null) return x;
            switch (x.def) {
                case EPin(inner):
                    var u = switch (inner.def) { case EParen(p): p; default: inner; };
                    switch (u.def) { case EVar(_): found = u; default: }
                default:
            }
            return x;
        });
        return found;
    }

    static function repairStmts(stmts: Array<ElixirAST>): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        var declared = new Map<String,Bool>();
        var lastWildcardIdx:Int = -1;
        // Helper: mark declared from a statement
        inline function markDeclared(s:ElixirAST):Void {
            switch (s.def) {
                case EMatch(PVar(nm), _): declared.set(nm, true);
                case EBinary(Match, left, _): switch (left.def) { case EVar(nm2): declared.set(nm2, true); default: }
                default:
            }
        }
        for (i in 0...stmts.length) {
            var s = stmts[i];
            var pushed = false;
            // Track wildcard-literal assignment candidates
            switch (s.def) {
                case EMatch(PWildcard, rhs) if (isLiteral(rhs)):
                    lastWildcardIdx = out.length;
                    out.push(s); pushed = true;
                case EBinary(Match, left, rhs2) if (isLiteral(rhs2)):
                    var isWild = switch (left.def) {
                        case EVar(v) if (v == "_"): true;
                        case EUnderscore: true;
                        default: false;
                    };
                    if (isWild) { lastWildcardIdx = out.length; out.push(s); pushed = true; }
                default:
            }
            // If where/2 with pinned var and we have a previous wildcard, promote it
            if (!pushed) {
                var repaired = false;
                inline function tryRepairForArgs(args:Array<ElixirAST>):Void {
                    if (args == null || args.length < 2) return;
                    var cond = args[args.length - 1];
                    var pinnedName = extractPinnedName(cond);
                    var pinnedVar:Null<ElixirAST> = null;
                    if (pinnedName == null) pinnedVar = findPinnedInnerVar(cond);
                    if (pinnedName != null && !declared.exists(pinnedName)) {
                        if (lastWildcardIdx >= 0) {
                            // Rewrite prior wildcard to bind pinnedName
                            var prev = out[lastWildcardIdx];
                            switch (prev.def) {
                                case EMatch(PWildcard, rhs3):
                                    out[lastWildcardIdx] = makeASTWithMeta(EMatch(PVar(pinnedName), rhs3), prev.metadata, prev.pos);
                                    declared.set(pinnedName, true);
                                    repaired = true;
                                case EBinary(Match, leftPrev, rhsPrev):
                                    var isWildPrev = switch (leftPrev.def) {
                                        case EVar(vp) if (vp == "_"): true;
                                        case EUnderscore: true;
                                        default: false;
                                    };
                                    if (isWildPrev) {
                                        out[lastWildcardIdx] = makeASTWithMeta(EBinary(Match, makeAST(EVar(pinnedName)), rhsPrev), prev.metadata, prev.pos);
                                        declared.set(pinnedName, true);
                                        repaired = true;
                                    }
                                default:
                            }
                        } else if (lastWildcardIdx < 0) {
                            // Fallback: search backward in out for a wildcard literal to promote
                            var k = out.length - 1;
                            while (k >= 0 && !repaired) {
                                switch (out[k].def) {
                                    case EMatch(PWildcard, rhs4) if (isLiteral(rhs4)):
                                        out[k] = makeASTWithMeta(EMatch(PVar(pinnedName), rhs4), out[k].metadata, out[k].pos);
                                        declared.set(pinnedName, true);
                                        repaired = true;
                                    case EBinary(Match, leftK, rhsK):
                                        var isWildK = switch (leftK.def) {
                                            case EVar(vk) if (vk == "_"): true;
                                            case EUnderscore: true;
                                            default: false;
                                        };
                                        if (isWildK && isLiteral(rhsK)) {
                                            out[k] = makeASTWithMeta(EBinary(Match, makeAST(EVar(pinnedName)), rhsK), out[k].metadata, out[k].pos);
                                            declared.set(pinnedName, true);
                                            repaired = true;
                                        }
                                    default:
                                }
                                k--;
                            }
                        }
                    } else if (pinnedVar != null && pinnedVar.metadata != null && pinnedVar.metadata.sourceVarId != null) {
                        var pvId:Int = pinnedVar.metadata.sourceVarId;
                        // Attempt varId-based promotion
                        // Prefer the last wildcard with matching varId metadata (if present)
                        if (lastWildcardIdx >= 0) {
                            var prev2 = out[lastWildcardIdx];
                            var prevId:Null<Int> = (prev2.metadata != null && prev2.metadata.varId != null) ? prev2.metadata.varId : null;
                            if (prevId != null && prevId == pvId) {
                                // Use the printed name from pinnedVar EVar
                                var pinnedName2 = switch (pinnedVar.def) { case EVar(nm): nm; default: null; };
                                if (pinnedName2 != null) {
                                    switch (prev2.def) {
                                        case EMatch(PWildcard, rhs5):
                                            out[lastWildcardIdx] = makeASTWithMeta(EMatch(PVar(pinnedName2), rhs5), prev2.metadata, prev2.pos);
                                            declared.set(pinnedName2, true);
                                            repaired = true;
                                        case EBinary(Match, leftPrev2, rhsPrev2):
                                            var isWildPrev2 = switch (leftPrev2.def) {
                                                case EVar(vp2) if (vp2 == "_"): true;
                                                case EUnderscore: true;
                                                default: false;
                                            };
                                            if (isWildPrev2) {
                                                out[lastWildcardIdx] = makeASTWithMeta(EBinary(Match, makeAST(EVar(pinnedName2)), rhsPrev2), prev2.metadata, prev2.pos);
                                                declared.set(pinnedName2, true);
                                                repaired = true;
                                            }
                                        default:
                                    }
                                }
                            }
                        }
                    }
                }
                switch (s.def) {
                    case ERemoteCall(mod, func, args) if (func == "where"): tryRepairForArgs(args);
                    case EMatch(_, rhs):
                        switch (rhs.def) {
                            case ERemoteCall(mod2, func2, args2) if (func2 == "where"): tryRepairForArgs(args2);
                            default:
                        }
                    case EBinary(Match, _, rhsB):
                        switch (rhsB.def) {
                            case ERemoteCall(mod3, func3, args3) if (func3 == "where"): tryRepairForArgs(args3);
                            default:
                        }
                    default:
                }
                out.push(s);
                // Mark declared after pushing
                markDeclared(s);
                if (repaired) {
                    // Reset wildcard pointer — already consumed
                    lastWildcardIdx = -1;
                }
            } else {
                // Wildcard pushed; do not forget to mark declared if it actually declares (it doesn't)
            }
        }
        return out;
    }
}

#end
