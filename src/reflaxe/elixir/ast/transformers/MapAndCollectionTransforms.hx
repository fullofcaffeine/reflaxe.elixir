package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.EMapPair;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTBuilder;
import haxe.macro.Expr.Position;

/**
 * MapAndCollectionTransforms: AST transformation passes for maps and collections
 * 
 * WHY: Map and collection operations in Haxe may generate verbose imperative patterns
 *      that should be transformed into idiomatic Elixir functional patterns.
 * 
 * WHAT: Contains transformation passes that optimize map and collection operations:
 *       - Map builder collapse: Convert Map.put sequences to literal maps
 *       - List effect lifting: Extract side-effects from list literals
 * 
 * HOW: Each pass analyzes patterns involving maps and collections and transforms
 *      them into more idiomatic Elixir equivalents.
 * 
 * ARCHITECTURE BENEFITS:
 * - Separation of Concerns: Collection logic isolated from main transformer
 * - Single Responsibility: Each pass handles one collection pattern
 * - Idiomatic Output: Generates functional Elixir patterns
 * - Performance: Eliminates unnecessary intermediate variables
 */
class MapAndCollectionTransforms {
    
    /**
     * Map builder collapse pass
     * 
     * WHY: Sequential Map.put calls create verbose imperative code
     * WHAT: Collapses Map.put builder patterns into literal map syntax
     * HOW: Detects temp map variable with sequential puts and converts to literal
     * 
     * PATTERN:
     * Before:
     *   temp = %{}
     *   temp = Map.put(temp, :key1, value1)
     *   temp = Map.put(temp, :key2, value2)
     *   temp
     * 
     * After:
     *   %{key1: value1, key2: value2}
     */
    public static function mapBuilderCollapsePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EBlock(statements):
                    var collapsed = tryCollapseMapBuilder(statements, node.metadata, node.pos);
                    if (collapsed != null) {
                        return collapsed;
                    }
                    return node;
                default:
                    return node;
            }
        });
    }

    
    private static function tryCollapseMapBuilder(statements: Array<ElixirAST>, metadata: ElixirMetadata, pos: Position): Null<ElixirAST> {
        if (statements == null || statements.length < 2) {
            return null;
        }

        var tempName: String = null;
        var pairs: Array<EMapPair> = null;

        switch(statements[0].def) {
            case EMatch(pattern, initExpr):
                switch pattern {
                    case PVar(name):
                        tempName = name;
#if debug_map_literal
                        trace('[MapCollapse] temp var=' + tempName);
#end
                    default:
                        return null;
                }

                switch(initExpr.def) {
                    case EMap(initialPairs):
                        pairs = initialPairs.copy();
#if debug_map_literal
                        trace('[MapCollapse] initial pairs count=' + pairs.length);
#end
                    default:
                        return null;
                }
            default:
                return null;
        }

        if (tempName == null) {
            return null;
        }

        for (i in 1...statements.length - 1) {
            var stmt = statements[i];
            switch(stmt.def) {
                case EBinary(Match, leftExpr, rightExpr):
                    switch(leftExpr.def) {
                        case EVar(varName) if (varName == tempName):
#if debug_map_literal
                            trace('[MapCollapse] assignment to ' + varName);
#end
                        default:
                            return null;
                    }

                    switch(rightExpr.def) {
                        case ERemoteCall(moduleExpr, funcName, args) if (funcName == "put" && args.length == 3):
#if debug_map_literal
                            trace('[MapCollapse] Map.put detected');
#end
                            switch(moduleExpr.def) {
                                case EVar(moduleName) if (moduleName == "Map"):
                                default:
                                    return null;
                            }

                            switch(args[0].def) {
                                case EVar(varName) if (varName == tempName):
                                default:
                                    return null;
                            }

                            pairs.push({key: args[1], value: args[2]});
#if debug_map_literal
                            trace('[MapCollapse] appended pair #' + pairs.length);
#end
                        default:
                            return null;
                    }
                default:
                    return null;
            }
        }

        switch(statements[statements.length - 1].def) {
            case EVar(varName) if (varName == tempName):
#if debug_map_literal
                trace('[MapCollapse] success - collapsing to literal');
#end
                return makeASTWithMeta(EMap(pairs), metadata, pos);
            default:
                return null;
        }
    }
    
    /**
     * List effect lifting pass
     * 
     * WHY: Side-effecting expressions in list literals can cause evaluation order issues
     * WHAT: Lifts side-effects out of list literals into temporary variables
     * HOW: Detects complex expressions in lists and extracts them to temp vars
     * 
     * PATTERN:
     * Before: [compute(), other.method(), value]
     * After:
     *   tmp1 = compute()
     *   tmp2 = other.method()
     *   [tmp1, tmp2, value]
     */
    public static function listEffectLiftingPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EList(items):
                    var needsLifting = false;
                    for (item in items) {
                        if (hasComplexExpression(item)) {
                            needsLifting = true;
                            break;
                        }
                    }
                    
                    if (needsLifting) {
                        var statements: Array<ElixirAST> = [];
                        var newItems: Array<ElixirAST> = [];
                        var tempCounter = 0;
                        
                        for (item in items) {
                            if (hasComplexExpression(item)) {
                                var tempVar = "tmp_list_" + tempCounter++;
                                statements.push(makeAST(EMatch(PVar(tempVar), item)));
                                newItems.push(makeAST(EVar(tempVar)));
                            } else {
                                newItems.push(item);
                            }
                        }
                        
                        statements.push(makeAST(EList(newItems)));
                        return makeAST(EBlock(statements));
                    }
                    
                    return node;
                default:
                    return node;
            }
        });
    }
    
    private static function hasComplexExpression(ast: ElixirAST): Bool {
        return switch(ast.def) {
            case ECall(_, _, _): true;
            case ERemoteCall(_, _, _): true;
            case EBinary(_, _, _): true;
            case EUnary(_, _): true;
            case ECase(_, _): true;
            case EIf(_, _, _): true;
            case ECond(_): true;
            case EBlock(_): true;
            default: false;
        };
    }
}

#end
