package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DropResidualWildcardDowncasePostTransforms
 *
 * WHAT
 * - Post-final cleanup to drop stray `_ = String.downcase(search_query)` once a
 *   proper `query = String.downcase(search_query)` binder has been established.
 *
 * WHY
 * - Some late passes may reintroduce or demote binders to wildcard; this removes
 *   redundant pure assignments to keep output clean and idiomatic.
 */
class DropResidualWildcardDowncasePostTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts) if (stmts.length > 0): makeASTWithMeta(EBlock(clean(stmts)), n.metadata, n.pos);
                case EDo(stmts2) if (stmts2.length > 0): makeASTWithMeta(EDo(clean(stmts2)), n.metadata, n.pos);
                default: n;
            }
        });
    }

    static function isQueryBinder(s: ElixirAST): Bool {
        return switch (s.def) {
            case EBinary(Match, left, rhs):
                var isQ = switch (left.def) { case EVar(nm) if (nm == "query"): true; default: false; };
                if (!isQ) false else isDowncase(rhs);
            case EMatch(pat, rhs2):
                var isQ2 = switch (pat) { case PVar(nm2) if (nm2 == "query"): true; default: false; };
                if (!isQ2) false else isDowncase(rhs2);
            default: false;
        };
    }
    static function isDowncase(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1): true;
            default: false;
        };
    }
    static function isWildcardDowncase(s: ElixirAST): Bool {
        return switch (s.def) {
            case EBinary(Match, left, rhs):
                var isWild = switch (left.def) { case EVar(nm) if (nm == "_"): true; case EUnderscore: true; default: false; };
                isWild && isDowncase(rhs);
            case EMatch(PWildcard, rhs2): isDowncase(rhs2);
            default: false;
        };
    }
    static function clean(stmts: Array<ElixirAST>): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        var seenQueryBinder = false;
        for (i in 0...stmts.length) {
            var s = stmts[i];
            if (isQueryBinder(s)) {
                seenQueryBinder = true;
                out.push(s);
                continue;
            }
            if (seenQueryBinder && isWildcardDowncase(s)) {
                // Drop redundant wildcard downcase after establishing `query`
                #if debug_filter_query_consolidate
                Sys.println('[DropResidualWildcardDowncasePost] Dropping redundant wildcard downcase after query binder');
                #end
                continue;
            }
            out.push(s);
        }
        return out;
    }
}

#end
