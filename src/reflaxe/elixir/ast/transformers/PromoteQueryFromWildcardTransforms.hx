package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PromoteQueryFromWildcardTransforms
 *
 * WHAT
 * - Promote a preceding wildcard assignment `_ = String.downcase(x)` into a
 *   named binding `query = String.downcase(x)` when the immediate next
 *   statement is `Enum.filter(list, fn ... -> ... end)` whose predicate body
 *   references `query` and there is no prior binding for `query` in the block.
 *
 * WHY
 * - Hygiene passes may discard explicit `query` binders into `_ = ...` while
 *   later transforms normalize filter predicates to use `query`. Promoting the
 *   wildcard back to `query` restores the intended local without name heuristics
 *   tied to app code.
 *
 * HOW
 * - For EBlock/EDo statements, scan pairs (s[i], s[i+1]):
 *   - s[i] is `_ = String.downcase(arg)` (EMatch(PWildcard, rhs))
 *   - s[i+1] is Enum.filter(..., EFn(clauses)) and predicate body references `query`
 *   - No prior binding for `query` appears in statements 0..i-1
 *   → Replace s[i] with `query = String.downcase(arg)`
 *
 * EXAMPLES
 * Elixir (before):
 *   _ = String.downcase(term)
 *   Enum.filter(list, fn -> String.contains?(query, term) end)
 * Elixir (after):
 *   query = String.downcase(term)
 *   Enum.filter(list, fn -> String.contains?(query, term) end)
 */
class PromoteQueryFromWildcardTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts) if (stmts.length > 1): makeASTWithMeta(EBlock(promote(stmts, n)), n.metadata, n.pos);
                case EDo(stmts2) if (stmts2.length > 1): makeASTWithMeta(EDo(promote(stmts2, n)), n.metadata, n.pos);
                default: n;
            }
        });
    }

    static function promote(stmts:Array<ElixirAST>, ctx: ElixirAST): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        function hasDefinedQuery(before:Int): Bool {
            for (k in 0...before) switch (stmts[k].def) {
                case EBinary(Match, left, _): switch (left.def) { case EVar(nm) if (nm == "query"): return true; default: }
                case EMatch(pat, _): switch (pat) { case PVar(n) if (n == "query"): return true; default: }
                default:
            }
            return false;
        }
        function bodyUsesQuery(e: ElixirAST): Bool {
            var found = false;
            ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST {
                if (found) return x;
                switch (x.def) {
                    case EVar(nm) if (nm == "query"): found = true; return x;
                    default: return x;
                }
            });
            return found;
        }
        var i = 0;
        while (i < stmts.length) {
            var s = stmts[i];
            if (i + 1 < stmts.length) {
                var next = stmts[i + 1];
                var isWildcardDowncase = switch (s.def) {
                    case EMatch(PWildcard, rhs): switch (rhs.def) {
                        case ERemoteCall({def: EVar(m)}, "downcase", _ ) if (m == "String"): true;
                        default: false;
                    }
                    case EBinary(Match, leftWild, rhs2):
                        var isWild = switch (leftWild.def) { case EVar(nm) if (nm == "_"): true; default: false; };
                        if (!isWild) false else switch (rhs2.def) {
                            case ERemoteCall({def: EVar(m2)}, "downcase", _ ) if (m2 == "String"): true;
                            default: false;
                        }
                    default: false;
                };
                var nextUsesQueryInFilter = switch (next.def) {
                    case ERemoteCall({def: EVar(m2)}, "filter", args) if (m2 == "Enum" && args.length == 2):
                        switch (args[1].def) { case EFn(clauses) if (clauses.length == 1): bodyUsesQuery(clauses[0].body); default: false; }
                    case ECall(_, "filter", args2) if (args2.length == 2):
                        switch (args2[1].def) { case EFn(clauses2) if (clauses2.length == 1): bodyUsesQuery(clauses2[0].body); default: false; }
                    case EMatch(_, rhsNext):
                        switch (rhsNext.def) {
                            case ERemoteCall({def: EVar(m3)}, "filter", a3) if (m3 == "Enum" && a3.length == 2):
                                switch (a3[1].def) { case EFn(clauses3) if (clauses3.length == 1): bodyUsesQuery(clauses3[0].body); default: false; }
                            case ECall(_, "filter", a4) if (a4.length == 2):
                                switch (a4[1].def) { case EFn(clauses4) if (clauses4.length == 1): bodyUsesQuery(clauses4[0].body); default: false; }
                            default: false;
                        }
                    default: false;
                };
                if (isWildcardDowncase && nextUsesQueryInFilter && !hasDefinedQuery(i)) {
                    // Promote wildcard to `query` binder
                    switch (s.def) {
                        case EMatch(PWildcard, rhsPromote):
                            out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhsPromote), ctx.metadata, ctx.pos));
                            i++;
                            continue;
                        case EBinary(Match, _, rhsPromote2):
                            out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhsPromote2), ctx.metadata, ctx.pos));
                            i++;
                            continue;
                        default:
                    }
                }
            }
            out.push(s);
            i++;
        }
        return out;
    }
}

#end
