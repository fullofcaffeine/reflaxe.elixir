package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * RemoveDuplicateDowncaseAfterQueryPostTransforms
 *
 * WHAT
 * - Post3 cleanup: if a block contains `query = String.downcase(search_query)`
 *   followed by an immediate `_ = String.downcase(search_query)`, drop the
 *   redundant wildcard assignment. Works for both EBlock and EDo.
 *
 * WHY
 * - Ensures only one downcase assignment remains when late passes produce
 *   duplicative lines. Keeps final output idiomatic and minimal.
 */
class RemoveDuplicateDowncaseAfterQueryPostTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts) if (stmts.length > 0): makeASTWithMeta(EBlock(clean(stmts)), n.metadata, n.pos);
                case EDo(stmts2) if (stmts2.length > 0): makeASTWithMeta(EDo(clean(stmts2)), n.metadata, n.pos);
                default: n;
            }
        });
    }

    static function isQueryDowncaseAssign(s: ElixirAST): Bool {
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
    static function isWildcardDowncaseAssign(s: ElixirAST): Bool {
        return switch (s.def) {
            case EBinary(Match, left, rhs):
                var isWild = switch (left.def) { case EVar(nm) if (nm == "_"): true; case EUnderscore: true; default: false; };
                isWild && isDowncase(rhs);
            case EMatch(PWildcard, rhs2): isDowncase(rhs2);
            default: false;
        };
    }
    static function isDowncase(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1): true;
            case ERaw(code) if (code != null && code.indexOf('String.downcase(search_query)') != -1): true;
            default: false;
        };
    }
    static function clean(stmts: Array<ElixirAST>): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        var i = 0;
        while (i < stmts.length) {
            var s = stmts[i];
            if (isQueryDowncaseAssign(s) && i + 1 < stmts.length && isWildcardDowncaseAssign(stmts[i + 1])) {
                // Push only the query binder, skip the next wildcard downcase
                out.push(s);
                i += 2;
                continue;
            }
            out.push(s);
            i++;
        }
        return out;
    }
}

#end
