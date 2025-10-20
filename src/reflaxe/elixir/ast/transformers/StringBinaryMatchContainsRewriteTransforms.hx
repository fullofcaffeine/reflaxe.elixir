package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StringBinaryMatchContainsRewriteTransforms
 *
 * WHAT
 * - Rewrites boolean predicates of the form `not Kernel.is_nil(:binary.match(a, b))`
 *   to idiomatic `String.contains?(a, b)`.
 *
 * WHY
 * - Haxe string search patterns (indexOf >= 0) may lower to match/is_nil constructs.
 *   In Elixir, `String.contains?/2` is clearer and avoids pitfalls with :nomatch handling.
 *
 * HOW
 * - Walk the AST and detect `EUnary(Not, ERemoteCall(Kernel, "is_nil", [ERemoteCall(:binary, "match", [a,b])]))`
 *   and rewrite to `ERemoteCall(String, "contains?", [a,b])` preserving metadata/pos.
 * - This is shape-only, no app-coupled heuristics.
 */
class StringBinaryMatchContainsRewriteTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EUnary(Not, inner):
                    switch (inner.def) {
                        case ERemoteCall(target, "is_nil", [arg]):
                            // Allow Kernel.is_nil/1 or is_nil/1 (unqualified)
                            var isKernel = switch (target) {
                                case null: true; // is_nil/1
                                case {def: EVar(k)} if (k == "Kernel"): true;
                                default: false;
                            };
                            if (!isKernel) return n;
                            switch (arg.def) {
                                case ERemoteCall(modNode, "match", [a, b]):
                                    var isBinary = switch (modNode.def) {
                                        case EAtom(m) if (m == "binary"): true;
                                        case EVar(m2) if (m2 == ":binary" || m2 == "binary"): true;
                                        default: false;
                                    };
                                    if (!isBinary) return n;
                                    makeASTWithMeta(ERemoteCall(makeAST(EVar("String")), "contains?", [a, b]), n.metadata, n.pos);
                                default:
                                    n;
                            }
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
