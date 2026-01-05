package reflaxe.elixir.ast.transformers;

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;
import reflaxe.elixir.ast.naming.ElixirAtom;

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
 *
 * EXAMPLES
 * Haxe:
 *   var users = [];
 *   for (u in 0...n) users.push(u);
 * Elixir (after lowering, before):
 *   Enum.reduce_while(..., {users}, fn _, {users} -> {:cont, {users}} end)
 * Elixir (after):
 *   {users} = Enum.reduce_while(...)
 */
@:nullSafety(Off)
class ReduceWhileAccumulatorTransform {
    
    /**
     * Main transformation pass for fixing reduce_while accumulators
     */
    public static function reduceWhileAccumulatorPass(ast: ElixirAST): ElixirAST {
        #if debug_reduce_while_transform
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
        return transformBodyRecursive(body, accVarNames, new Map<String, ElixirAST>(), false);
    }

    static function transformBodyRecursive(body: ElixirAST, accVarNames: Array<String>, accUpdates: Map<String, ElixirAST>, preserveAssignments: Bool = false): ElixirAST {
        if (body == null) return null;
        
        switch(body.def) {
            case ETry(tryBody, rescueClauses, catchClauses, afterBlock, elseBlock):
                // Preserve try/catch structure while still rewriting accumulator assignments
                // inside the try body (common for break/continue lowering).
                var transformedTryBody = transformBodyRecursive(tryBody, accVarNames, accUpdates.copy(), preserveAssignments);
                var transformedRescue = rescueClauses == null ? [] : [
                    for (r in rescueClauses) {
                        pattern: r.pattern,
                        varName: r.varName,
                        body: transformBodyRecursive(r.body, accVarNames, accUpdates.copy(), true)
                    }
                ];
                var transformedCatch = catchClauses == null ? [] : [
                    for (c in catchClauses) {
                        kind: c.kind,
                        pattern: c.pattern,
                        body: transformBodyRecursive(c.body, accVarNames, accUpdates.copy(), true)
                    }
                ];
                var transformedAfter = afterBlock != null ? transformBodyRecursive(afterBlock, accVarNames, accUpdates.copy(), true) : null;
                var transformedElse = elseBlock != null ? transformBodyRecursive(elseBlock, accVarNames, accUpdates.copy(), true) : null;
                return makeAST(ETry(transformedTryBody, transformedRescue, transformedCatch, transformedAfter, transformedElse));

            case EIf(condition, thenBranch, elseBranch):
                // ⚠️ FIX: Don't remove if-expressions that contain return tuples
                // These are the lambda's main control flow (do-while pattern)
                var hasReturnTuple = containsReturnTuple(thenBranch) ||
                                     (elseBranch != null && containsReturnTuple(elseBranch));

                #if debug_ast_transformer trace('[DEBUG] EIf processing - hasReturnTuple: $hasReturnTuple'); #end
                #if debug_ast_transformer trace('[DEBUG] thenBranch containsReturnTuple: ${containsReturnTuple(thenBranch)}'); #end
                if (elseBranch != null) {
                    #if debug_ast_transformer trace('[DEBUG] elseBranch containsReturnTuple: ${containsReturnTuple(elseBranch)}'); #end
                }

                if (hasReturnTuple) {
                    // This if-expression is the lambda's main control flow
                    // Preserve it and recursively transform branches WITHOUT removing assignments
                    #if debug_ast_transformer trace('[XRay ReduceWhile] Preserving if-expression with return tuples (main control flow)'); #end

                    var transformedThen = transformBodyRecursive(thenBranch, accVarNames, accUpdates.copy(), true);
                    var transformedElse = elseBranch != null ? transformBodyRecursive(elseBranch, accVarNames, accUpdates.copy(), true) : null;
                    return makeAST(EIf(condition, transformedThen, transformedElse));
                }

                // Check if this if statement contains accumulator assignments
                var hasAccAssignments = checkForAccumulatorAssignments(thenBranch, accVarNames) ||
                                        (elseBranch != null && checkForAccumulatorAssignments(elseBranch, accVarNames));

                if (hasAccAssignments) {
                    // This if contains accumulator assignments, we need to capture the result
                    // Generate a new variable name for the result
                    var resultVarName = findAccumulatorVarInIf(thenBranch, elseBranch, accVarNames);

                    if (resultVarName != null) {
                        // Transform to capture the assignment result
                        var transformedIf = makeAST(EIf(
                            condition,
                            extractValueFromAssignment(thenBranch, resultVarName),
                            elseBranch != null ? extractValueFromAssignment(elseBranch, resultVarName) : null
                        ));

                        // Store the update for later use
                        accUpdates.set(resultVarName, transformedIf);

                        #if debug_reduce_while_transform
                        #end

                        // Return empty block (the assignment is captured in accUpdates)
                        // We can't return null as it breaks subsequent transformations
                        return makeAST(EBlock([]));
                    }
                }
                
                // Regular if without accumulator assignments
                var transformedThen = transformBodyRecursive(thenBranch, accVarNames, accUpdates.copy());
                var transformedElse = elseBranch != null ? transformBodyRecursive(elseBranch, accVarNames, accUpdates.copy()) : null;
                return makeAST(EIf(condition, transformedThen, transformedElse));
                
            case ECase(expr, branches):
                // Handle case statements with accumulator updates
                var hasAccAssignments = false;
                var accVarName: String = null;
                
                // Check if any branch contains accumulator assignments
                for (branch in branches) {
                    if (checkForAccumulatorAssignments(branch.body, accVarNames)) {
                        hasAccAssignments = true;
                        // Find which accumulator variable is being assigned
                        accVarName = findAssignedAccumulator(branch.body, accVarNames);
                        if (accVarName != null) break;
                    }
                }
                
                if (hasAccAssignments && accVarName != null) {
                    // Transform case branches to return values instead of assigning.
                    // When we are preserving assignments (main control-flow with return tuples),
                    // we cannot rely on update-substitution into {:cont/:halt, acc} because that
                    // would double-apply updates. Instead, rewrite to a direct rebinding:
                    //
                    //   acc = case ... do
                    //     {:some, v} -> Map.put(acc, k, v)
                    //     {:none} -> acc
                    //   end
                    //
                    // This avoids Elixir's "unused/shadowed variable" warnings inside clause bodies
                    // and keeps the accumulator threaded correctly within the reducer.
                    var transformedBranches = [];
                    for (branch in branches) {
                        var extracted = extractValueFromAssignment(branch.body, accVarName);
                        var transformedBody = extracted;
                        if (transformedBody == branch.body) {
                            // No assignment in this branch: preserve side effects, but ensure we
                            // return the accumulator unchanged so all branches unify.
                            var inner = transformBodyRecursive(branch.body, accVarNames, accUpdates.copy(), preserveAssignments);
                            if (preserveAssignments) {
                                transformedBody = switch (inner.def) {
                                    case EBlock(sts): makeAST(EBlock(sts.concat([makeAST(EVar(accVarName))])));
                                    case EDo(sts2): makeAST(EBlock(sts2.concat([makeAST(EVar(accVarName))])));
                                    case ENil: makeAST(EVar(accVarName));
                                    default: makeAST(EBlock([inner, makeAST(EVar(accVarName))]));
                                };
                            } else {
                                transformedBody = inner;
                            }
                        }
                        transformedBranches.push({
                            pattern: branch.pattern,
                            guard: branch.guard,
                            body: transformedBody
                        });
                    }

                    var transformedCase = makeAST(ECase(expr, transformedBranches));

                    if (preserveAssignments) {
                        return makeAST(EBinary(Match, makeAST(EVar(accVarName)), transformedCase));
                    }

                    // Non-control-flow context: store the case expression as an update and splice it
                    // into the next {:cont/:halt, acc} tuple.
                    accUpdates.set(accVarName, transformedCase);

                    #if debug_reduce_while_transform
                    #end

                    return makeAST(EBlock([]));
                } else {
                    // Regular case without accumulator assignments
                    var transformedBranches = [];
                    for (branch in branches) {
                        transformedBranches.push({
                            pattern: branch.pattern,
                            guard: branch.guard,
                            body: transformBodyRecursive(branch.body, accVarNames, accUpdates.copy())
                        });
                    }
                    return makeAST(ECase(expr, transformedBranches));
                }
                
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
                            #end

                            // ⚠️ FIX: If we're preserving assignments (inside main control flow), keep them
                            if (preserveAssignments) {
                                #if debug_reduce_while_transform
                                #end
                                transformedExprs.push(makeAST(EMatch(PVar(varName), value)));
                            }
                            // Otherwise, don't add the assignment to the output (will be merged into return tuple)
                        case EBinary(Match, {def: EVar(varName)}, value) if (accVarNames.indexOf(varName) >= 0):
                            localUpdates.set(varName, value);
                            if (preserveAssignments) {
                                transformedExprs.push(makeAST(EBinary(Match, makeAST(EVar(varName)), value)));
                            }
                            
                        case ETuple([atom, accTuple]):
                            // This is a return statement {:cont, acc} or {:halt, acc}
                            switch(atom.def) {
                                // OR patterns like "cont" | "halt" don't work with abstract types, use guard clause instead
                                case EAtom(atom) if (atom == "cont" || atom == "halt"):
                                    // Build new accumulator with updates
                                    // IMPORTANT:
                                    // When `preserveAssignments` is true, accumulator assignments were kept in the
                                    // block (to preserve control-flow shapes). In that case the accumulator vars
                                    // already hold the updated values, and substituting RHS expressions into the
                                    // return tuple can silently change semantics:
                                    //   acc_len = acc_len + n
                                    //   {:cont, {acc_len}}  -- correct
                                    // would become:
                                    //   {:cont, {acc_len + n}} -- double-add (incorrect)
                                    // So only apply RHS-substitution when we *removed* the assignments.
                                    var newAcc = preserveAssignments ? accTuple : applyAccumulatorUpdates(accTuple, accVarNames, localUpdates);
                                    transformedExprs.push(makeAST(ETuple([makeAST(EAtom(atom)), newAcc])));
                                    
                                default:
                                    transformedExprs.push(expr);
                            }
                            
                        default:
                            // Recursively transform other expressions
                            var transformed = transformBodyRecursive(expr, accVarNames, localUpdates, preserveAssignments);
                            // Only add non-null results
                            if (transformed != null) {
                                transformedExprs.push(transformed);
                            }
                    }
                }
                
                return makeAST(EBlock(transformedExprs));
                
            case ETuple([atom, accTuple]):
                // Direct return of {:cont/:halt, accumulator}
                switch(atom.def) {
                    // OR patterns like "cont" | "halt" don't work with abstract types, use guard clause instead
                    case EAtom(atom) if (atom == "cont" || atom == "halt"):
                        // Apply any accumulated updates
                        var newAcc = preserveAssignments ? accTuple : applyAccumulatorUpdates(accTuple, accVarNames, accUpdates);
                        return makeAST(ETuple([makeAST(EAtom(atom)), newAcc]));
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
     * Check if an AST node contains return tuples {:cont/:halt, accumulator}
     * These indicate the node is part of the lambda's main control flow
     */
    static function containsReturnTuple(node: ElixirAST): Bool {
        if (node == null) return false;

        switch(node.def) {
            case ETuple([atom, _]):
                // Check if this is a {:cont/:halt, acc} tuple
                switch(atom.def) {
                    case EAtom(a) if (a == "cont" || a == "halt"):
                        return true;
                    default:
                }

            case EBlock(exprs):
                // Check if any expression in the block is a return tuple
                for (expr in exprs) {
                    if (containsReturnTuple(expr)) {
                        return true;
                    }
                }

            case EIf(_, thenBranch, elseBranch):
                // Recursively check branches
                if (containsReturnTuple(thenBranch)) return true;
                if (elseBranch != null && containsReturnTuple(elseBranch)) return true;

            default:
        }

        return false;
    }

    /**
     * Check if an AST node represents the Enum module
     */
    static function isEnumModule(module: ElixirAST): Bool {
        return switch(module.def) {
            case EVar("Enum"): true;
            case EAtom(atom) if (atom == "Elixir.Enum"): true;
            default: false;
        };
    }
    
    /**
     * Check if an AST node contains assignments to accumulator variables
     */
    static function checkForAccumulatorAssignments(node: ElixirAST, accVarNames: Array<String>): Bool {
        if (node == null) return false;
        
        switch(node.def) {
            case EMatch(PVar(varName), _) if (accVarNames.indexOf(varName) >= 0):
                return true;
            case EBinary(Match, {def: EVar(varName)}, _) if (accVarNames.indexOf(varName) >= 0):
                return true;
            case EBlock(exprs):
                for (expr in exprs) {
                    if (checkForAccumulatorAssignments(expr, accVarNames)) {
                        return true;
                    }
                }
                return false;
            case EIf(_, thenBranch, elseBranch):
                return checkForAccumulatorAssignments(thenBranch, accVarNames) ||
                       (elseBranch != null && checkForAccumulatorAssignments(elseBranch, accVarNames));
            default:
                return false;
        }
    }
    
    /**
     * Find which accumulator variable is being assigned in an if statement
     */
    static function findAccumulatorVarInIf(thenBranch: ElixirAST, elseBranch: ElixirAST, accVarNames: Array<String>): Null<String> {
        // Check then branch for assignments
        var varName = findAssignedAccumulator(thenBranch, accVarNames);
        if (varName != null) return varName;
        
        // Check else branch if it exists
        if (elseBranch != null) {
            return findAssignedAccumulator(elseBranch, accVarNames);
        }
        
        return null;
    }
    
    /**
     * Find an accumulator variable being assigned in an AST node
     */
    static function findAssignedAccumulator(node: ElixirAST, accVarNames: Array<String>): Null<String> {
        if (node == null) return null;
        
        switch(node.def) {
            case EMatch(PVar(varName), _) if (accVarNames.indexOf(varName) >= 0):
                return varName;
            case EBinary(Match, {def: EVar(varName)}, _) if (accVarNames.indexOf(varName) >= 0):
                return varName;
            case EBlock(exprs):
                for (expr in exprs) {
                    var result = findAssignedAccumulator(expr, accVarNames);
                    if (result != null) return result;
                }
                return null;
            default:
                return null;
        }
    }
    
    /**
     * Extract the value being assigned from an assignment statement
     */
    static function extractValueFromAssignment(node: ElixirAST, varName: String): ElixirAST {
        if (node == null) return null;
        
        switch(node.def) {
            case EMatch(PVar(name), value) if (name == varName):
                return value;
            case EBinary(Match, {def: EVar(name)}, value) if (name == varName):
                return value;
            case EBlock(exprs):
                for (expr in exprs) {
                    var result = extractValueFromAssignment(expr, varName);
                    if (result != null) return result;
                }
                return node; // Return the whole block if no assignment found
            default:
                return node;
        }
    }
}
