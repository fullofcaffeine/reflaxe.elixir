package reflaxe.elixir.ast.transformers;

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;

using reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceWhileAccumulatorTransform: Fixes variable shadowing in reduce_while loops
 * 
 * WHY: When variables are mutated inside Enum.reduce_while, Elixir doesn't allow
 * direct reassignment like `result = result <> "x"`. Instead, mutations must be
 * returned as part of the accumulator tuple {:cont, {new_values...}}.
 * 
 * WHAT: Transforms variable assignments inside reduce_while bodies to proper
 * accumulator updates, eliminating "variable unused" warnings from shadowing.
 * 
 * HOW:
 * - Detects Enum.reduce_while calls with tuple accumulators
 * - Finds variable assignments that shadow accumulator variables
 * - Transforms assignments into accumulator updates
 * - Ensures proper tuple return values with {:cont/:halt, updated_accumulator}
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles reduce_while accumulator threading
 * - Generates idiomatic Elixir: Proper functional accumulator patterns
 * - Eliminates warnings: No more variable shadowing issues
 * - Preserves semantics: Maintains correct execution order
 * 
 * EDGE CASES:
 * - Nested reduce_while calls
 * - Multiple variable mutations in one iteration
 * - Conditional mutations (inside if/case)
 * - Early returns with :halt
 */
@:nullSafety(Off)
class ReduceWhileAccumulatorTransform {
    
    /**
     * Main transformation pass for fixing reduce_while accumulators
     */
    public static function reduceWhileAccumulatorPass(ast: ElixirAST): ElixirAST {
        #if debug_reduce_while_transform
        trace("[XRay ReduceWhile] Starting reduce_while accumulator transformation");
        #end
        
        return transformReduceWhile(ast);
    }
    
    static function transformReduceWhile(node: ElixirAST): ElixirAST {
        // First recursively transform children
        var transformedNode = ElixirASTTransformer.transformAST(node, transformReduceWhile);
        
        // Then check if this is a reduce_while that needs transformation
        switch(transformedNode.def) {
            case ERemoteCall(module, "reduce_while", args) if (isEnumModule(module)):
                #if debug_reduce_while_transform
                trace("[XRay ReduceWhile] Found Enum.reduce_while call");
                #end
                
                if (args.length >= 3) {
                    var collection = args[0];
                    var initialAcc = args[1];
                    var fnArg = args[2];
                    
                    // Check if the function has accumulator variables
                    switch(fnArg.def) {
                        case EFn(clauses):
                            var transformedClauses = [];
                            for (clause in clauses) {
                                var transformedClause = transformReduceWhileClause(clause, initialAcc);
                                transformedClauses.push(transformedClause);
                            }
                            
                            // Return the transformed reduce_while
                            return makeAST(ERemoteCall(
                                module,
                                "reduce_while",
                                [collection, initialAcc, makeAST(EFn(transformedClauses))]
                            ));
                            
                        default:
                            // Not a function literal, return as-is
                            return transformedNode;
                    }
                }
                
            default:
                // Not a reduce_while call
        }
        
        return transformedNode;
    }
    
    /**
     * Transform a single clause of the reduce_while function
     */
    static function transformReduceWhileClause(clause: {args: Array<EPattern>, guard: Null<ElixirAST>, body: ElixirAST}, 
                                               initialAcc: ElixirAST): {args: Array<EPattern>, guard: Null<ElixirAST>, body: ElixirAST} {
        // Extract accumulator variable names from the pattern
        var accVarNames = extractAccumulatorVars(clause.args);
        
        if (accVarNames.length == 0) {
            // No accumulator variables to track
            return clause;
        }
        
        #if debug_reduce_while_transform
        trace('[XRay ReduceWhile] Accumulator variables: $accVarNames');
        #end
        
        // Transform the body to handle variable mutations properly
        var transformedBody = transformClauseBody(clause.body, accVarNames);
        
        return {
            args: clause.args,
            guard: clause.guard,
            body: transformedBody
        };
    }
    
    /**
     * Extract accumulator variable names from function arguments
     */
    static function extractAccumulatorVars(args: Array<EPattern>): Array<String> {
        var varNames = [];
        
        // Usually pattern is [_, {var1, var2, ...}] for reduce_while
        if (args.length >= 2) {
            switch(args[1]) {
                case PTuple(patterns):
                    for (p in patterns) {
                        switch(p) {
                            case PVar(name):
                                varNames.push(name);
                            default:
                        }
                    }
                case PVar(name):
                    varNames.push(name);
                default:
            }
        }
        
        return varNames;
    }
    
    /**
     * Transform the clause body to properly handle accumulator updates
     */
    static function transformClauseBody(body: ElixirAST, accVarNames: Array<String>): ElixirAST {
        // Look for patterns where accumulator variables are reassigned
        switch(body.def) {
            case EBlock(exprs):
                // Check if any expressions are assignments to accumulator variables
                var transformedExprs = [];
                var accumulatorUpdates = new Map<String, ElixirAST>();
                
                for (i in 0...exprs.length) {
                    var expr = exprs[i];
                    
                    // Check if this is an assignment to an accumulator variable
                    switch(expr.def) {
                        case EMatch(PVar(varName), value) if (accVarNames.indexOf(varName) >= 0):
                            // This is an accumulator variable update
                            // Store the update instead of doing direct assignment
                            accumulatorUpdates.set(varName, value);
                            
                            #if debug_reduce_while_transform
                            trace('[XRay ReduceWhile] Found accumulator update: $varName');
                            #end
                            
                        case ETuple([atom, _]):
                            // This might be a return statement {:cont, acc} or {:halt, acc}
                            // Replace the accumulator with updated values
                            switch(atom.def) {
                                case EAtom("cont" | "halt"):
                                    // Build new accumulator tuple with updates
                                    var newAcc = buildUpdatedAccumulator(accVarNames, accumulatorUpdates);
                                    transformedExprs.push(makeAST(ETuple([atom, newAcc])));
                                    
                                default:
                                    transformedExprs.push(expr);
                            }
                            
                        default:
                            transformedExprs.push(expr);
                    }
                }
                
                return makeAST(EBlock(transformedExprs));
                
            case ETuple([atom, acc]):
                // Direct return of {:cont/:halt, accumulator}
                // This is already correct
                return body;
                
            default:
                // For other patterns, return as-is
                return body;
        }
    }
    
    /**
     * Build an updated accumulator tuple with new values
     */
    static function buildUpdatedAccumulator(varNames: Array<String>, updates: Map<String, ElixirAST>): ElixirAST {
        var accValues = [];
        
        for (varName in varNames) {
            if (updates.exists(varName)) {
                // Use the updated value
                accValues.push(updates.get(varName));
            } else {
                // Use the original variable
                accValues.push(makeAST(EVar(varName)));
            }
        }
        
        // Handle the simple case of a single variable
        if (accValues.length == 1) {
            return accValues[0];
        }
        
        // Return as tuple for multiple values
        return makeAST(ETuple(accValues));
    }
    
    /**
     * Check if an AST node represents the Enum module
     */
    static function isEnumModule(module: ElixirAST): Bool {
        return switch(module.def) {
            case EVar("Enum"): true;
            case EAtom("Elixir.Enum"): true;
            default: false;
        };
    }
}