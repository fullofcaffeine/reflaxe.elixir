package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StructAndMapTransforms: Transforms for struct/map assignment and statement-context rebindings
 *
 * WHAT
 * - structFieldAssignmentTransformPass: Converts imperative field assignments into struct updates
 * - statementContextTransformPass: Rebinds side-effecting calls used as statements
 *
 * WHY
 * - Elixir data is immutable; field assignment patterns must emit updates to new structs.
 * - Calls like Map.put/Enum.* used in statement context must write back to the original variable.
 *
 * HOW
 * - Uses structural matching to rewrite patterns, preserving idiomatic Elixir shapes.
 */
@:nullSafety(Off)
class StructAndMapTransforms {
    public static function structFieldAssignmentTransformPass(ast: ElixirAST): ElixirAST {
        var structVarTracking: Map<String, String> = new Map();
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch (node.def) {
                case EBlock(expressions):
                    var transformed: Array<ElixirAST> = [];
                    var i = 0;
                    while (i < expressions.length) {
                        var expr = expressions[i];
                        switch (expr.def) {
                            case EMatch(PVar(varName), rhs):
                                switch (rhs.def) {
                                    case ECall(_, funcName, _) if (funcName == "worker" || funcName == "supervisor" || funcName == "temp_worker"):
                                        structVarTracking.set(varName, varName);
                                    case ERemoteCall(_, funcName, _) if (funcName == "worker" || funcName == "supervisor" || funcName == "temp_worker"):
                                        structVarTracking.set(varName, varName);
                                    default:
                                }

                                if (i + 1 < expressions.length) {
                                    var nextExpr = expressions[i + 1];
                                    switch (nextExpr.def) {
                                        case EMatch(PVar(fieldName), fieldValue):
                                            if (structVarTracking.exists(varName) && (fieldName == "restart" || fieldName == "shutdown" || fieldName == "type" || fieldName == "strategy" || fieldName == "max_restarts" || fieldName == "max_seconds")) {
                                                transformed.push(expr);
                                                var mapPut = makeAST(EMatch(
                                                    PVar(varName),
                                                    makeAST(ERemoteCall(
                                                        makeAST(EVar("Map")),
                                                        "put",
                                                        [makeAST(EVar(varName)), makeAST(EAtom(fieldName)), fieldValue]
                                                    ))
                                                ));
                                                transformed.push(mapPut);
                                                i += 2;
                                                continue;
                                            }
                                        default:
                                    }
                                }
                                transformed.push(expr);
                            default:
                                transformed.push(expr);
                        }
                        i++;
                    }
                    return (transformed.length > 0) ? makeASTWithMeta(EBlock(transformed), node.metadata, node.pos) : node;
                default:
                    node;
            }
        });
    }

    public static function statementContextTransformPass(ast: ElixirAST): ElixirAST {
        function transformWithContext(node: ElixirAST, isStatementContext: Bool): ElixirAST {
            if (node == null || node.def == null) return node;

            var transformed = switch (node.def) {
                case EDefmodule(name, doBlock):
                    makeASTWithMeta(EDefmodule(name, transformWithContext(doBlock, true)), node.metadata, node.pos);
                case EBlock(expressions):
                    var newExpressions = [];
                    for (i in 0...expressions.length) {
                        var isLast = (i == expressions.length - 1);
                        var childContext = isLast ? isStatementContext : true;
                        newExpressions.push(transformWithContext(expressions[i], childContext));
                    }
                    makeASTWithMeta(EBlock(newExpressions), node.metadata, node.pos);
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, transformWithContext(body, false)), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, transformWithContext(body, false)), node.metadata, node.pos);
                case EIf(condition, thenBranch, elseBranch):
                    makeASTWithMeta(EIf(transformWithContext(condition, false), transformWithContext(thenBranch, isStatementContext), elseBranch != null ? transformWithContext(elseBranch, isStatementContext) : null), node.metadata, node.pos);
                case ECase(expr, clauses):
                    makeASTWithMeta(ECase(transformWithContext(expr, false), clauses.map(c -> {
                        return { pattern: c.pattern, guard: c.guard != null ? transformWithContext(c.guard, false) : null, body: transformWithContext(c.body, isStatementContext) };
                    })), node.metadata, node.pos);
                case EMatch(pattern, expr):
                    makeASTWithMeta(EMatch(pattern, transformWithContext(expr, false)), node.metadata, node.pos);
                case ECall(target, method, args):
                    makeASTWithMeta(ECall(target != null ? transformWithContext(target, false) : null, method, args.map(a -> transformWithContext(a, false))), node.metadata, node.pos);
                case ERemoteCall(module, func, args):
                    makeASTWithMeta(ERemoteCall(transformWithContext(module, false), func, args.map(a -> transformWithContext(a, false))), node.metadata, node.pos);
                default:
                    node;
            };

            if (isStatementContext) {
                switch (transformed.def) {
                    case ERemoteCall(mod, func, args):
                        switch (args[0].def) {
                            case EVar(name):
                                return makeASTWithMeta(EMatch(PVar(name), transformed), transformed.metadata, transformed.pos);
                            default:
                                return transformed;
                        }
                    case ECall(target, func, args) if (target == null && args.length > 0):
                        switch (args[0].def) {
                            case EVar(name):
                                return makeASTWithMeta(EMatch(PVar(name), transformed), transformed.metadata, transformed.pos);
                            default:
                                return transformed;
                        }
                    default:
                        return transformed;
                }
            }
            return transformed;
        }
        return transformWithContext(ast, true);
    }

    public static function fluentApiOptimizationPass(ast: ElixirAST): ElixirAST {
        #if debug_fluent_api
        trace("[FluentApiOptimization] Starting optimization pass");
        #end

        return ElixirASTTransformer.transformNode(ast, function(node) {
            switch(node.def) {
                case EDef(name, args, guards, body):
                    var optimizedBody = optimizeFluentBody(body);
                    if (optimizedBody != body) {
                        #if debug_fluent_api
                        trace('[FluentApiOptimization] Optimized function: $name');
                        #end
                        return makeAST(EDef(name, args, guards, optimizedBody));
                    }
                case EDefp(name, args, guards, body):
                    var optimizedBody = optimizeFluentBody(body);
                    if (optimizedBody != body) {
                        #if debug_fluent_api
                        trace('[FluentApiOptimization] Optimized private function: $name');
                        #end
                        return makeAST(EDefp(name, args, guards, optimizedBody));
                    }
                default:
            }
            return node;
        });
    }

    static function optimizeFluentBody(body: ElixirAST): ElixirAST {
        if (body == null) return null;
        switch(body.def) {
            case EBlock(exprs) if (exprs.length == 2):
                var firstExpr = exprs[0];
                var secondExpr = exprs[1];
                switch(firstExpr.def) {
                    case EMatch(PVar("struct"), updateExpr):
                        switch(secondExpr.def) {
                            case EVar("struct"):
                                return makeASTWithMeta(EBlock([updateExpr]), body.metadata, body.pos);
                            default:
                        }
                    default:
                }
                return body;
            default:
                return body;
        }
    }
}

#end
