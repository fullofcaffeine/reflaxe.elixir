package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import StringTools;

/**
 * DuplicateEffectfulCallPruneTransforms
 *
 * WHAT
 * - Removes immediately duplicated effectful calls when the first call's
 *   result is not used and the very next statement re-invokes the same call
 *   (typically in a case expression).
 *
 * WHY
 * - Some builder/transformer paths can emit a stray `_ = Repo.insert(cs)` or
 *   `var = _ = Repo.update(cs)` followed immediately by `case Repo.insert(cs) do ...`.
 *   This causes duplicate side effects (double INSERT/UPDATE). We should emit
 *   only the case-driven invocation.
 *
 * HOW
 * - On function bodies, scan EBlock statements for pairs [s[i], s[i+1]].
 * - If s[i] ultimately evaluates to an ERemoteCall (possibly wrapped inside
 *   one or more match operators), and s[i+1] is an ECase on an identical
 *   ERemoteCall (same module, function, and argument shapes), drop s[i].
 * - Structural comparison is used to avoid name heuristics.
 *
 * EXAMPLES
 *   _ = Repo.insert(cs)
 *   case Repo.insert(cs) do ... end       ->     case Repo.insert(cs) do ... end
 *
 *   updated = _ = Repo.update(changeset)
 *   case Repo.update(changeset) do ...    ->     case Repo.update(changeset) do ...
 */
class DuplicateEffectfulCallPruneTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (looksLikePresenceModule(name, n)):
                    n;
                case EDefmodule(name, doBlock) if (looksLikePresenceModule(name, n)):
                    n;
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, pruneInBody(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, pruneInBody(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function looksLikePresenceModule(name:String, node:ElixirAST):Bool {
        if (node != null && node.metadata != null && node.metadata.isPresence == true) return true;
        if (name == null) return false;
        return StringTools.endsWith(name, ".Presence") || StringTools.endsWith(name, "Web.Presence");
    }

    static function pruneInBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out: Array<ElixirAST> = [];
                var i = 0;
                while (i < stmts.length) {
                    if (i + 1 < stmts.length) {
                        var first = stmts[i];
                        var second = stmts[i + 1];
                        var firstCall = extractRightmostCall(first);
                        var secondCaseCall = extractCaseHeadCall(second);
                        if (firstCall != null && secondCaseCall != null && callsEqual(firstCall, secondCaseCall)) {
                            // Drop the first duplicate invocation
                            out.push(second);
                            i += 2;
                            continue;
                        }
                    }
                    out.push(stmts[i]);
                    i++;
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }

    static function extractRightmostCall(n: ElixirAST): Null<ElixirAST> {
        // Walk down match operators to find the rightmost expression
        function unwrap(e: ElixirAST): ElixirAST {
            return switch (e.def) {
                case EBinary(Match, _, r): unwrap(r);
                case EMatch(_, r2): unwrap(r2);
                case EParen(inner): unwrap(inner);
                default: e;
            }
        }
        var e = unwrap(n);
        return switch (e.def) {
            case ERemoteCall(_, _, _): e;
            case ECall(_, _, _): e;
            default: null;
        }
    }

    static function extractCaseHeadCall(n: ElixirAST): Null<ElixirAST> {
        return switch (n.def) {
            case ECase(expr, _):
                var ex = expr;
                while (ex != null && ex.def != null) switch (ex.def) {
                    case EParen(inner): ex = inner; continue;
                    default: break;
                }
                return switch (ex.def) {
                    case ERemoteCall(_, _, _): ex;
                    case ECall(_, _, _): ex;
                    default: null;
                }
            default:
                null;
        }
    }

    static function callsEqual(a: ElixirAST, b: ElixirAST): Bool {
        return switch [a.def, b.def] {
            case [ERemoteCall(ma, fa, aa), ERemoteCall(mb, fb, ab)]:
                exprEqual(ma, mb) && fa == fb && argsEqual(aa, ab);
            case [ECall(ta, fa, aa), ECall(tb, fb, ab)]:
                exprEqual(ta, tb) && fa == fb && argsEqual(aa, ab);
            default: false;
        }
    }

    static function argsEqual(a: Array<ElixirAST>, b: Array<ElixirAST>): Bool {
        if (a == null && b == null) return true;
        if (a == null || b == null) return false;
        if (a.length != b.length) return false;
        for (i in 0...a.length) if (!exprEqual(a[i], b[i])) return false;
        return true;
    }

    static function exprEqual(a: ElixirAST, b: ElixirAST): Bool {
        // Shallow structural equality sufficient for our patterns
        if (a == null || b == null) return a == b;
        if (Type.enumIndex(a.def) != Type.enumIndex(b.def)) return false;
        return switch [a.def, b.def] {
            case [EVar(na), EVar(nb)]: na == nb;
            case [EAtom(aa), EAtom(ab)]: aa == ab;
            case [EString(sa), EString(sb)]: sa == sb;
            case [EInteger(ia), EInteger(ib)]: ia == ib;
            case [ERemoteCall(ma, fa, aa), ERemoteCall(mb, fb, ab)]: callsEqual(a, b);
            case [ECall(ta, fa, aa), ECall(tb, fb, ab)]: callsEqual(a, b);
            case [EAccess(ta, ka), EAccess(tb, kb)]: exprEqual(ta, tb) && exprEqual(ka, kb);
            case [EParen(pa), EParen(pb)]: exprEqual(pa, pb);
            default: Std.string(a.def) == Std.string(b.def);
        }
    }
}

#end
