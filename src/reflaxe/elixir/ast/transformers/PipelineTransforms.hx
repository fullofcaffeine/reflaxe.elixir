package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PipelineTransforms: Detection and conversion of sequential reassignment chains to |> pipelines
 *
 * WHAT
 * - pipelineOptimizationPass: Scans EBlock sequences for var = f(var, ...) chains and emits EPipe
 * - detectAndOptimizePipeline: Helper that returns an assignment with a constructed pipeline
 *
 * WHY
 * - Aligns with idiomatic Elixir style and reduces noise from repeated reassignments.
 *
 * HOW
 * - Operates structurally on EMatch(EVar, E(Call|RemoteCall)) sequences with first arg equal to EVar.
 * - Requires at least two sequential steps to construct a pipeline.
 */
@:nullSafety(Off)
class PipelineTransforms {
    public static function pipelineOptimizationPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(expressions):
                    var optimized = detectAndOptimizePipeline(expressions);
                    optimized != null ? optimized : node;
                default:
                    node;
            }
        });
    }

    public static function detectAndOptimizePipeline(expressions: Array<ElixirAST>): Null<ElixirAST> {
        if (expressions == null || expressions.length < 2) return null;

        var pipelineOps = [];
        var baseVar: String = null;
        var lastExpr: ElixirAST = null;

        for (expr in expressions) {
            switch (expr.def) {
                case EMatch(PVar(name), call):
                    switch (call.def) {
                        case ECall(target, func, args):
                            if (args.length > 0) switch (args[0].def) {
                                case EVar(argName) if (argName == name):
                                    if (baseVar == null) baseVar = name;
                                    if (baseVar == name) {
                                        pipelineOps.push({ func: func, args: args.slice(1), target: target });
                                        lastExpr = expr;
                                        continue;
                                    }
                                default:
                            }
                        case ERemoteCall(module, func, args):
                            if (args.length > 0) switch (args[0].def) {
                                case EVar(argName) if (argName == name):
                                    if (baseVar == null) baseVar = name;
                                    if (baseVar == name) {
                                        pipelineOps.push({ func: func, args: args.slice(1), target: module });
                                        lastExpr = expr;
                                        continue;
                                    }
                                default:
                            }
                        default:
                    }
                default:
            }

            if (pipelineOps.length >= 2) break; else { pipelineOps = []; baseVar = null; }
        }

        if (pipelineOps.length >= 2) {
            var pipeline = makeAST(EVar(baseVar));
            for (op in pipelineOps) {
                pipeline = makeAST(EPipe(
                    pipeline,
                    (op.target != null)
                        ? makeAST(ERemoteCall(op.target, op.func, op.args))
                        : makeAST(ECall(null, op.func, op.args))
                ));
            }
            return makeAST(EMatch(PVar(baseVar), pipeline));
        }

        return null;
    }
}

#end

