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
        
        // Handle null nodes (which can indicate removed nodes)
        if (transformedNode == null) {
            return null;
        }
        
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
        // Deep transform to handle nested structures
        return transformBodyRecursive(body, accVarNames, new Map<String, ElixirAST>());
    }
    
    static function transformBodyRecursive(body: ElixirAST, accVarNames: Array<String>, accUpdates: Map<String, ElixirAST>): ElixirAST {
        if (body == null) return null;
        
        switch(body.def) {
            case EIf(condition, thenBranch, elseBranch):
                // Transform both branches of the if statement
                var transformedThen = transformBodyRecursive(thenBranch, accVarNames, accUpdates.copy());
                var transformedElse = elseBranch != null ? transformBodyRecursive(elseBranch, accVarNames, accUpdates.copy()) : null;
                return makeAST(EIf(condition, transformedThen, transformedElse));
                
            case EBlock(exprs):
                // Process block expressions
                var transformedExprs = [];
                var localUpdates = accUpdates.copy();
                
                for (i in 0...exprs.length) {
                    var expr = exprs[i];
                    
                    // Check if this is an assignment to an accumulator variable
                    switch(expr.def) {
                        case EMatch(PVar(varName), value) if (accVarNames.indexOf(varName) >= 0):
                            // Store the update - we'll use it when we see the return tuple
                            localUpdates.set(varName, value);
                            
                            #if debug_reduce_while_transform
                            trace('[XRay ReduceWhile] Found accumulator update: $varName');
                            #end
                            // Don't add the assignment to the output
                            
                        case ETuple([atom, accTuple]):
                            // This is a return statement {:cont, acc} or {:halt, acc}
                            switch(atom.def) {
                                case EAtom("cont" | "halt"):
                                    // Build new accumulator with updates
                                    var newAcc = applyAccumulatorUpdates(accTuple, accVarNames, localUpdates);
                                    transformedExprs.push(makeAST(ETuple([atom, newAcc])));
                                    
                                default:
                                    transformedExprs.push(expr);
                            }
                            
                        default:
                            // Recursively transform other expressions
                            transformedExprs.push(transformBodyRecursive(expr, accVarNames, localUpdates));
                    }
                }
                
                return makeAST(EBlock(transformedExprs));
                
            case ETuple([atom, accTuple]):
                // Direct return of {:cont/:halt, accumulator}
                switch(atom.def) {
                    case EAtom("cont" | "halt"):
                        // Apply any accumulated updates
                        var newAcc = applyAccumulatorUpdates(accTuple, accVarNames, accUpdates);
                        return makeAST(ETuple([atom, newAcc]));
                    default:
                        return body;
                }
                
            default:
                // For other patterns, return as-is
                return body;
        }
    }
    
    /**
     * Apply accumulator updates to the return tuple
     */
    static function applyAccumulatorUpdates(accTuple: ElixirAST, varNames: Array<String>, updates: Map<String, ElixirAST>): ElixirAST {
        // Check if updates map has any entries
        var hasUpdates = false;
        for (key in updates.keys()) {
            hasUpdates = true;
            break;
        }
        
        if (!hasUpdates) {
            return accTuple;
        }
        
        switch(accTuple.def) {
            case ETuple(elements):
                // Update tuple elements
                var newElements = [];
                for (i in 0...elements.length) {
                    if (i < varNames.length && updates.exists(varNames[i])) {
                        newElements.push(updates.get(varNames[i]));
                    } else {
                        newElements.push(elements[i]);
                    }
                }
                return makeAST(ETuple(newElements));
                
            case EVar(name) if (updates.exists(name)):
                // Single variable accumulator
                return updates.get(name);
                
            default:
                return accTuple;
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