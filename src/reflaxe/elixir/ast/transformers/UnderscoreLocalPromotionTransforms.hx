package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer.OptimizedUsageIndex;

typedef DeclIndex = {
    var suffix:Array<Map<String,Bool>>;
}

/**
 * UnderscoreLocalPromotionTransforms
 *
 * WHAT
 * - Promote local variables assigned with an underscored name (e.g., `_this = ...`)
 *   to the base name (`this`) when the base is not otherwise declared in scope
 *   and the variable is referenced later in the same block.
 *
 * WHY
 * - Avoids warnings like "the underscored variable `_this` is used after being set".

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class UnderscoreLocalPromotionTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
                    var declIndex = buildDeclIndex(stmts);
                    var out:Array<ElixirAST> = [];
                    var renameMap:Map<String,String> = new Map();
                    for (i in 0...stmts.length) {
                        var stmt = stmts[i];
                        // Apply existing renames to current statement first
                        var stmtWithRenames = applyRenames(stmt, renameMap);
                        var rewrittenStmt = switch (stmtWithRenames.def) {
                            case EMatch(PVar(varName), rhs) if (shouldPromote(varName, useIndex, declIndex, i)):
                                var base = varName.substr(1);
                                renameMap.set(varName, base);
                                makeASTWithMeta(EMatch(PVar(base), rhs), stmtWithRenames.metadata, stmtWithRenames.pos);
                            case EBinary(Match, left, right):
                                switch (left.def) {
                                    case EVar(vname) if (shouldPromote(vname, useIndex, declIndex, i)):
                                        var baseName = vname.substr(1);
                                        renameMap.set(vname, baseName);
                                        makeASTWithMeta(EBinary(Match, makeAST(EVar(baseName)), right), stmtWithRenames.metadata, stmtWithRenames.pos);
                                    default: stmtWithRenames;
                                }
                            default:
                                stmtWithRenames;
                        };
                        out.push(rewrittenStmt);
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function isUnderscored(name: String): Bool {
        return name != null && name.length > 1 && name.charAt(0) == '_';
    }

    static inline function shouldPromote(varName: String, useIndex: OptimizedUsageIndex, declIndex: DeclIndex, idx: Int): Bool {
        if (!isUnderscored(varName)) return false;
        var baseName = varName.substr(1);
        return OptimizedVarUseAnalyzer.usedLater(useIndex, idx + 1, varName) && !declaredLater(declIndex, idx + 1, baseName);
    }

    static function buildDeclIndex(stmts: Array<ElixirAST>): DeclIndex {
        var suffix:Array<Map<String,Bool>> = [];
        if (stmts == null) {
            suffix.push(new Map());
            return { suffix: suffix };
        }
        suffix[stmts.length] = new Map<String,Bool>();
        var i = stmts.length - 1;
        while (i >= 0) {
            var nextMap = suffix[i + 1];
            var current = new Map<String,Bool>();
            for (k in nextMap.keys()) current.set(k, true);
            collectTopLevelDecls(stmts[i], current);
            suffix[i] = current;
            i--;
        }
        return { suffix: suffix };
    }

    static function declaredLater(idx: DeclIndex, start: Int, name: String): Bool {
        if (idx == null || idx.suffix == null || name == null || name.length == 0) return false;
        var pos = start;
        if (pos < 0) pos = 0;
        if (pos >= idx.suffix.length) return false;
        return idx.suffix[pos].exists(name);
    }

    static inline function addDecl(out: Map<String, Bool>, name: String): Void {
        if (out == null || name == null || name.length == 0 || name == "_") return;
        if (!out.exists(name)) out.set(name, true);
    }

    static function collectTopLevelDecls(stmt: ElixirAST, out: Map<String, Bool>): Void {
        if (stmt == null || stmt.def == null) return;
        switch (stmt.def) {
            case EMatch(pattern, _):
                collectPatternDecls(pattern, out);
            case EBinary(Match, left, _):
                switch (left.def) {
                    case EVar(v): addDecl(out, v);
                    default:
                }
            default:
        }
    }

    static function collectPatternDecls(pat: EPattern, out: Map<String, Bool>): Void {
        if (pat == null) return;
        switch (pat) {
            case PVar(name):
                addDecl(out, name);
            case PAlias(varName, inner):
                addDecl(out, varName);
                collectPatternDecls(inner, out);
            case PTuple(elements) | PList(elements):
                for (p in elements) collectPatternDecls(p, out);
            case PCons(head, tail):
                collectPatternDecls(head, out);
                collectPatternDecls(tail, out);
            case PMap(pairs):
                for (p in pairs) collectPatternDecls(p.value, out);
            case PStruct(_, fields):
                for (f in fields) collectPatternDecls(f.value, out);
            case PBinary(segments):
                for (s in segments) collectPatternDecls(s.pattern, out);
            case PPin(_):
                // Pins are variable uses, not declarations.
            default:
        }
    }

    static function applyRenames(node: ElixirAST, rename: Map<String,String>): ElixirAST {
        if (Lambda.count(rename) == 0) return node;
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (rename.exists(v)):
                    makeASTWithMeta(EVar(rename.get(v)), n.metadata, n.pos);
                default: n;
            }
        });
    }
}

#end
