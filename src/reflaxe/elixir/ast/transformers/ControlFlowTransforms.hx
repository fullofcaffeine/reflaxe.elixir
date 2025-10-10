package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControlFlowTransforms: Structural control-flow rewrites
 *
 * WHAT
 * - conditionalReassignmentPass: Rewrites in-place reassignments inside if to functional style.
 *
 * WHY
 * - Avoids shadowing/reassignment warnings and yields idiomatic Elixir.
 */
@:nullSafety(Off)
class ControlFlowTransforms {
    public static function conditionalReassignmentPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EBlock(expressions):
                    var transformed = [];
                    for (expr in expressions) {
                        if (expr == null || expr.def == null) continue;
                        switch(expr.def) {
                            case EIf(cond, thenBranch, null):
                                switch(thenBranch.def) {
                                    case EMatch(PVar(varName), value):
                                        if (referencesVariable(value, varName)) {
                                            var newIf = makeAST(EIf(cond, value, makeAST(EVar(varName))));
                                            transformed.push(makeAST(EMatch(PVar(varName), newIf)));
                                        } else {
                                            transformed.push(expr);
                                        }
                                    default:
                                        transformed.push(expr);
                                }
                            default:
                                transformed.push(expr);
                        }
                    }
                    return makeASTWithMeta(EBlock(transformed), node.metadata, node.pos);
                default:
                    return node;
            }
        });
    }

    static function referencesVariable(ast: ElixirAST, varName: String): Bool {
        var found = false;
        function visitor(node: ElixirAST): Void {
            if (found || node == null || node.def == null) return;
            switch(node.def) {
                case EVar(name) if (name == varName):
                    found = true;
                case ERemoteCall(_, _, args):
                    if (args.length > 0) switch(args[0].def) {
                        case EVar(name) if (name == varName): found = true;
                        default: for (arg in args) visitor(arg);
                    }
                default:
                    ElixirASTTransformer.transformAST(node, function(n) { visitor(n); return n; });
            }
        }
        visitor(ast);
        return found;
    }
}

#end

