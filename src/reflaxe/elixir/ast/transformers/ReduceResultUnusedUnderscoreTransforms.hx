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
        return rewriteNode(ast, new Map());
    }

    /**
     * Context-aware block rewrite.
     *
     * WHY
     * - This pass used to treat every EBlock independently. When loop lowerings
     *   compiled a `for` into a nested EBlock statement that ends with:
     *     acc = Enum.reduce(...)
     *   the `acc` rebind is often used *after the block* in the parent statement list.
     *   Block-local analysis would incorrectly underscore it to `_acc`, breaking semantics.
     *
     * HOW
     * - Thread an `outerUsedAfter` set into nested blocks, derived from the parent block's
     *   suffix-use index (plus any usage after the parent block itself).
     * - A reduce binder is considered "used" if referenced later in the same block OR in
     *   `outerUsedAfter`.
     */
    static function rewriteNode(node: ElixirAST, outerUsedAfter: Map<String, Bool>): ElixirAST {
        if (node == null || node.def == null) return node;

        return switch (node.def) {
            case EBlock(stmts):
                makeASTWithMeta(EBlock(rewriteStatements(stmts, outerUsedAfter)), node.metadata, node.pos);
            case EDo(stmts):
                makeASTWithMeta(EDo(rewriteStatements(stmts, outerUsedAfter)), node.metadata, node.pos);
            default:
                // Recurse and rewrite any nested EBlock nodes using the same `outerUsedAfter`
                ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
                    return switch (n.def) {
                        case EBlock(innerStmts):
                            makeASTWithMeta(EBlock(rewriteStatements(innerStmts, outerUsedAfter)), n.metadata, n.pos);
                        case EDo(innerStmts):
                            makeASTWithMeta(EDo(rewriteStatements(innerStmts, outerUsedAfter)), n.metadata, n.pos);
                        default:
                            n;
                    }
                });
        }
    }

    static function rewriteStatements(stmts: Array<ElixirAST>, outerUsedAfter: Map<String, Bool>): Array<ElixirAST> {
        if (stmts == null) return stmts;

        var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
        var out: Array<ElixirAST> = [];

        for (i in 0...stmts.length) {
            var stmt = stmts[i];
            var usedAfter = mergeUseSets(useIndex.suffix[i + 1], outerUsedAfter);

            // Rewrite nested blocks within the statement using "used after this statement".
            var rewrittenStmt = rewriteNode(stmt, usedAfter);

            // Then apply reduce-result underscoring to the statement itself (top-level in this block).
            switch (rewrittenStmt.def) {
                case EMatch(pat, rhs) if (isEnumReduceOrWhile(rhs)):
                    var names = extractNames(pat);
                    if (names.length > 0) {
                        var unused: Array<String> = [];
                        for (name in names) {
                            if (!usedAfter.exists(name)) unused.push(name);
                        }
                        if (unused.length > 0) {
                            var newPat = underscoreUnusedInPattern(pat, unused);
                            rewrittenStmt = makeASTWithMeta(EMatch(newPat, rhs), rewrittenStmt.metadata, rewrittenStmt.pos);
                        }
                    }
                default:
            }

            out.push(rewrittenStmt);
        }

        return out;
    }

    static function mergeUseSets(a: Map<String, Bool>, b: Map<String, Bool>): Map<String, Bool> {
        var out = new Map<String, Bool>();
        if (a != null) for (k in a.keys()) out.set(k, true);
        if (b != null) for (k in b.keys()) out.set(k, true);
        return out;
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
