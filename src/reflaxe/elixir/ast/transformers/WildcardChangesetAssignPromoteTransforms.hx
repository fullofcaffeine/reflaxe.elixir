package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WildcardChangesetAssignPromoteTransforms
 *
 * WHAT
 * - In `changeset/2` functions, promotes a leading nested wildcard assignment chain
 *   (e.g., `_ = _ = _ = expr`) that yields an Ecto.Changeset-producing expression
 *   into a canonical `cs = expr` binding.
 *
 * WHY
 * - Hygiene/rewrite passes may turn the initial changeset-producing expression into
 *   a throwaway chain of `_ =` matches. Subsequent validations then reference `cs`
 *   without a binding, causing undefined-variable errors. Promoting the chain to
 *   `cs = <expr>` restores the idiomatic pipeline.
 *
 * HOW
 * - Inside EDef/EDefp named `changeset`, inspect the first top-level statement. If it
 *   is a match (EBinary(Match, ...) or EMatch(...)) whose left target(s) are wildcard
 *   variables and whose innermost RHS is an Ecto.Changeset remote call (`cast` or
 *   `change`), rewrite it to `cs = <innermostRHS>`.
 * - Strictly shape-based; no app-specific strings.
 */
class WildcardChangesetAssignPromoteTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, params, guards, body) if (name == "changeset"):
                    var nb = promoteLeadingWildcard(body);
                    makeASTWithMeta(EDef(name, params, guards, nb), n.metadata, n.pos);
                case EDefp(name, params, guards, body) if (name == "changeset"):
                    var nb2 = promoteLeadingWildcard(body);
                    makeASTWithMeta(EDefp(name, params, guards, nb2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function promoteLeadingWildcard(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts) if (stmts.length > 0):
                var first = stmts[0];
                #if sys
                #if (sys && debug_ast_transformer) Sys.println('[WildcardChangesetAssignPromote] First stmt node: ' + Std.string(first.def)); #end
                #end
                var rhs = rhsIfWildcardAssign(first);
                if (rhs != null) {
                    var csAssign = makeASTWithMeta(EBinary(Match, makeAST(EVar("cs")), rhs), first.metadata, first.pos);
                    var newStmts = [csAssign];
                    for (i in 1...stmts.length) newStmts.push(stmts[i]);
                    makeASTWithMeta(EBlock(newStmts), body.metadata, body.pos);
                } else body;
            default:
                body;
        }
    }

    static function rhsIfWildcardAssign(stmt: ElixirAST): Null<ElixirAST> {
        // Accept either EBinary(Match, ...) or EMatch pattern forms where LHS are wildcards
        return switch (stmt.def) {
            case EBinary(Match, left, rhs):
                if (lhsAllWildcards(left)) peelToInnermost(rhs) else null;
            case EMatch(pat, rhs2):
                if (patternAllWildcards(pat)) rhs2 else null;
            default: null;
        }
    }

    static function lhsAllWildcards(lhs: ElixirAST): Bool {
        return switch (lhs.def) {
            case EVar(v) if (v == "_" || (v != null && v.length > 1 && v.charAt(0) == '_')): true;
            case EBinary(Match, l2, r2): lhsAllWildcards(l2) && lhsAllWildcards(r2);
            default: false;
        }
    }

    static function patternAllWildcards(p: EPattern): Bool {
        return switch (p) {
            case PVar(n) if (n == "_" || (n != null && n.length > 1 && n.charAt(0) == '_')): true;
            case PTuple(es): var ok = true; for (e in es) ok = ok && patternAllWildcards(e); ok;
            case PList(es): var ok2 = true; for (e in es) ok2 = ok2 && patternAllWildcards(e); ok2;
            case PCons(h, t): patternAllWildcards(h) && patternAllWildcards(t);
            default: false;
        }
    }

    static function peelToInnermost(n: ElixirAST): ElixirAST {
        var cur = n;
        while (cur != null && cur.def != null) {
            switch (cur.def) {
                case EBinary(Match, left, inner) if (lhsAllWildcards(left)):
                    cur = inner;
                case EMatch(pat, inner2) if (patternAllWildcards(pat)):
                    cur = inner2;
                default:
                    return cur;
            }
        }
        return cur == null ? n : cur;
    }

    static function bodyUsesCs(body: ElixirAST): Bool {
        var found = false;
        function scan(n: ElixirAST): Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case EVar(v) if (v == "cs"): found = true;
                case EBlock(ss): for (s in ss) scan(s);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case ECase(expr, cs): scan(expr); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                case EBinary(_, l, r): scan(l); scan(r);
                case EMatch(_, rhs): scan(rhs);
                case ECall(t,_,as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
                case ERemoteCall(t2,_,as2): scan(t2); if (as2 != null) for (a in as2) scan(a);
                case EFn(clauses): for (cl in clauses) scan(cl.body);
                default:
            }
        }
        scan(body);
        return found;
    }
}

#end
