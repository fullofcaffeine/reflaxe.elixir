package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * ReduceResultUnusedUnderscoreTransforms
 *
 * WHAT
 * - When a reduce/reduce_while result is rebound to local variables but those
 *   variables are not used later in the same block, underscore the binders to
 *   eliminate warnings (e.g., `{_all_users} = Enum.reduce_while(...)`).
 *
 * WHY
 * - While/loop lowerings may bind the reduce result just to keep shape. If the
 *   bound names are unused, Elixir warns. Underscoring the binders is the
 *   idiomatic fix.
 *
 * HOW
 * - For each EBlock([...]) statement list, look for EMatch(PVar/PTuple, ERemoteCall(Enum, ...))
 *   and scan subsequent statements for any usage of the bound names.
 *   - For unused PVar(name) → PVar("_" + name)
 *   - For PTuple([... PVar(name) ...]) → replace those fields with PWildcard when unused
 */
class ReduceResultUnusedUnderscoreTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
	            return switch (n.def) {
	                case EBlock(stmts):
	                    var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
	                    var out:Array<ElixirAST> = [];
	                    for (i in 0...stmts.length) {
	                        var stmt = stmts[i];
	                        switch (stmt.def) {
	                            case EMatch(pat, rhs) if (isEnumReduceOrWhile(rhs)):
	                                var names = extractNames(pat);
	                                if (names.length > 0) {
	                                    var unused = names.filter(name -> !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, name));
	                                    if (unused.length > 0) {
	                                        var newPat = underscoreUnusedInPattern(pat, unused);
	                                        out.push(makeASTWithMeta(EMatch(newPat, rhs), stmt.metadata, stmt.pos));
	                                    } else out.push(stmt);
	                                } else out.push(stmt);
	                            default:
	                                out.push(stmt);
	                        }
	                    }
	                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
	                default:
                    n;
            }
        });
    }

    static function isEnumReduceOrWhile(rhs: ElixirAST): Bool {
        return switch (rhs.def) {
            case ERemoteCall({def: EVar("Enum")}, fn, _): (fn == "reduce" || fn == "reduce_while");
            default: false;
        }
    }

    static function extractNames(pat: EPattern): Array<String> {
        return switch (pat) {
            case PVar(n): [n];
            case PTuple(elems):
                var out:Array<String> = [];
                for (p in elems) switch (p) { case PVar(nm): out.push(nm); default: }
                out;
            default: [];
        }
    }

    static function underscoreUnusedInPattern(pat: EPattern, unused: Array<String>): EPattern {
        return switch (pat) {
            case PVar(n):
                if (unused.indexOf(n) >= 0) PVar('_' + n) else pat;
            case PTuple(elems):
                var outElems:Array<EPattern> = [];
                for (p in elems) switch (p) {
                    case PVar(nm):
                        if (unused.indexOf(nm) >= 0) outElems.push(PWildcard) else outElems.push(p);
                    default: outElems.push(p);
                }
                PTuple(outElems);
            default:
                pat;
	        }
	    }
}

#end
