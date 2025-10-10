package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ExpressionTransforms: Core expression-level optimizations
 *
 * WHAT
 * - constantFoldingPass: Evaluate constant expressions at compile time.
 *
 * WHY
 * - Reduces runtime computation and aligns with idiomatic, concise Elixir output.
 *
 * HOW
 * - Walk expressions and fold arithmetic/boolean ops where both sides are literals.
 */
@:nullSafety(Off)
class ExpressionTransforms {
    public static function constantFoldingPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EBinary(op, left, right):
                    switch([left.def, right.def]) {
                        case [EInteger(l), EInteger(r)]:
                            var result = switch(op) {
                                case Add: l + r;
                                case Subtract: l - r;
                                case Multiply: l * r;
                                case Divide: Math.floor(l / r);
                                case Remainder: l % r;
                                case Less: l < r ? 1 : 0;
                                case Greater: l > r ? 1 : 0;
                                case LessEqual: l <= r ? 1 : 0;
                                case GreaterEqual: l >= r ? 1 : 0;
                                case Equal: l == r ? 1 : 0;
                                case NotEqual: l != r ? 1 : 0;
                                default: null;
                            };
                            if (result != null) {
                                if (op == Less || op == Greater || op == LessEqual || op == GreaterEqual || op == Equal || op == NotEqual) {
                                    makeASTWithMeta(EBoolean(result == 1), node.metadata, node.pos);
                                } else {
                                    makeASTWithMeta(EInteger(result), node.metadata, node.pos);
                                }
                            } else node;

                        case [EString(l), EString(r)] if (op == StringConcat):
                            makeASTWithMeta(EString(l + r), node.metadata, node.pos);

                        case [EList(l), EList(r)] if (op == Concat):
                            makeASTWithMeta(EList(l.concat(r)), node.metadata, node.pos);

                        default:
                            node;
                    }

                case EUnary(op, expr):
                    switch(expr.def) {
                        case EInteger(i) if (op == Negate):
                            makeASTWithMeta(EInteger(-i), node.metadata, node.pos);
                        case EBoolean(b) if (op == Not):
                            makeASTWithMeta(EBoolean(!b), node.metadata, node.pos);
                        default:
                            node;
                    }

                default:
                    node;
            }
        });
    }
}

#end

