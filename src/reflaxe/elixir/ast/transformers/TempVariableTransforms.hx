package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * TempVariableTransforms: AST transformation passes for temporary variable management
 * 
 * WHY: Temporary variables are generated during compilation but may create redundant
 *      or overly complex code patterns. These need to be optimized for idiomatic output.
 * 
 * WHAT: Contains transformation passes that detect and optimize temporary variable patterns:
 *       - Inline simple temp bindings in expression contexts
 *       - Clean up redundant temp alias assignments
 *       - Resolve variable references in case clauses
 * 
 * HOW: Each pass analyzes AST patterns involving temporary variables and transforms
 *      them into more idiomatic or efficient forms while preserving semantics.
 * 
 * ARCHITECTURE BENEFITS:
 * - Separation of Concerns: Temp variable logic isolated from main transformer
 * - Single Responsibility: Each pass handles one temp variable pattern
 * - Maintainable: Small focused functions for specific optimizations
 * - Testable: Each optimization can be tested independently
 * - Performance: Eliminates unnecessary variable allocations
 *
 * EXAMPLES
 * Haxe:
 *   var v = { field: (tmp = f(), g(tmp)) };
 * Elixir (after):
 *   v = %{field: g(f())}
 */
class TempVariableTransforms {
    
    /**
     * Inline temporary binding in expression contexts
     * 
     * WHY: Compiler generates temp bindings like `[tmp = expr, use(tmp)]` which are verbose
     * WHAT: Collapses simple temp bindings to direct usage in expression contexts
     * HOW: Detects 2-element blocks with temp assignment and single usage, replaces with inlined expression
     * 
     * PATTERN:
     * Before: `[tmp = complexExpr(), doSomething(tmp)]`
     * After: `doSomething(complexExpr())`
     * 
     * EDGE CASES:
     * - Preserves case expressions that need block context
     * - Only collapses in expression contexts (map values, function args, etc.)
     * - Preserves parentheses for precedence
     */
    public static function inlineTempBindingInExprPass(ast: ElixirAST): ElixirAST {
        // Helper functions for collapsing logic
        function replaceVar(node: ElixirAST, name: String, replacement: ElixirAST): ElixirAST {
            return ElixirASTTransformer.transformNode(node, function(n) {
                return switch(n.def) {
                    case EVar(v) if (v == name):
                        // Replace with a parenthesized expression to preserve precedence
                        makeAST(EParen(replacement));
                    case _:
                        n;
                };
            });
        }
        
        // Helper to check if a variable is used in an AST
        function containsVar(node: ElixirAST, varName: String): Bool {
            var found = false;
            iterateAST(node, function(n) {
                switch(n.def) {
                    case EVar(v) if (v == varName):
                        found = true;
                    default:
                }
            });
            return found;
        }
        
        // Determine if we're in an expression context where collapsing is safe
        function isInExpressionContext(parent: ElixirAST, child: ElixirAST): Bool {
            if (parent == null) return false;
            return switch(parent.def) {
                // Expression contexts where collapsing is safe
                case EMap(pairs): true; // Map field values
                case EKeywordList(pairs): true; // Keyword list values
                case ECall(_, _, _): true; // Function arguments
                case EBinary(_, _, _): true; // Binary operator operands
                case EUnary(_, _): true; // Unary operator operand
                case EParen(_): true; // Parenthesized expressions
                case EList(_): true; // List elements
                case ETuple(_): true; // Tuple elements
                case EMatch(_, _): true; // Right side of assignment/match
                
                // Statement contexts where we should NOT collapse
                case ECase(_, clauses): false; // Case clause bodies are statements
                case EDef(_, _, _, _): false; // Function bodies are statements
                case EDefp(_, _, _, _): false; // Private function bodies are statements
                case EDefmodule(_, _): false; // Module bodies are statements
                case EBlock(_): false; // Nested blocks are usually statement contexts
                case EIf(_, _, _): false; // If branches are statement contexts
                case ECond(clauses): false; // Cond clause bodies are statements
                
                default: false; // Conservative: don't collapse unless we're sure
            };
        }
        
        // Phase 1: Build parent map by walking the tree
        var parentOf = new haxe.ds.ObjectMap<ElixirAST, ElixirAST>();
        
        function walk(node: ElixirAST, parent: Null<ElixirAST>): Void {
            // Skip null nodes
            if (node == null) {
                return;
            }
            
            if (parent != null) {
                parentOf.set(node, parent);
            }
            
            // Walk all children based on node type
            switch(node.def) {
                case EBlock(exprs):
                    for (e in exprs) walk(e, node);
                    
                case ECall(target, method, args):
                    walk(target, node);
                    for (a in args) walk(a, node);
                    
                case EMap(pairs):
                    for (p in pairs) walk(p.value, node);
                    
                case EKeywordList(pairs):
                    for (p in pairs) walk(p.value, node);
                    
                case ETuple(values):
                    for (v in values) walk(v, node);
                    
                case EList(items):
                    for (i in items) walk(i, node);
                    
                case EBinary(op, left, right):
                    walk(left, node);
                    walk(right, node);
                    
                case EUnary(op, expr):
                    walk(expr, node);
                    
                case ECase(expr, clauses):
                    walk(expr, node);
                    for (c in clauses) {
                        if (c.guard != null) walk(c.guard, node);
                        walk(c.body, node);
                    }
                    
                case EIf(cond, thenB, elseB):
                    walk(cond, node);
                    walk(thenB, node);
                    if (elseB != null) walk(elseB, node);
                    
                case ECond(clauses):
                    for (c in clauses) {
                        walk(c.condition, node);
                        walk(c.body, node);
                    }
                    
                case EDef(name, args, guards, body):
                    if (guards != null) walk(guards, node);
                    walk(body, node);
                    
                case EDefp(name, args, guards, body):
                    if (guards != null) walk(guards, node);
                    walk(body, node);
                    
                case EDefmodule(name, body):
                    walk(body, node);
                    
                case EAssign(name):
                    // EAssign is for template assigns (@variable), no children
                    
                    
                case EParen(expr):
                    walk(expr, node);
                    
                case EMatch(pattern, expr):
                    // Pattern is usually not an expression, but walk the expr
                    walk(expr, node);
                    
                // Add more cases as needed for other node types
                default:
                    // Leaf nodes or nodes without children
            }
        }
        
        // Walk the entire tree to build parent map
        walk(ast, null);
        
        // Phase 2: Transform bottom-up, collapsing only when in expression context
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            var parent = parentOf.exists(node) ? parentOf.get(node) : null;
            var inExpr = parent != null && isInExpressionContext(parent, node);
            
            // Check if this is a collapsible block in an expression context
            var shouldCollapse = switch(node.def) {
                case EBlock(exprs) if (exprs.length == 2):
                    inExpr; // Only collapse in expression contexts
                default:
                    false;
            };
            
            if (!shouldCollapse) return node;
            
            // Try to collapse the block
            switch(node.def) {
                case EBlock(exprs) if (exprs.length == 2):
                    switch(exprs[0].def) {
                        case EMatch(PVar(tmp), bindExpr):
                            var second = exprs[1];

                            // Debug output to see what we're processing
                            #if debug_temp_binding
                            // DISABLED: trace('[InlineTempBindingInExpr] Processing block with temp var: ' + tmp);
                            // DISABLED: trace('[InlineTempBindingInExpr] bindExpr type: ' + Type.enumConstructor(bindExpr.def));
                            #end

                            // Check if tmp is actually used in the second expression
                            if (containsVar(second, tmp)) {
                                // Check if bindExpr is a case expression that needs preservation
                                var shouldPreserve = switch(bindExpr.def) {
                                    case ECase(_): true;
                                    case EBlock(exprs) if (exprs.length > 0):
                                        // Check if block ends with a case
                                        switch(exprs[exprs.length - 1].def) {
                                            case ECase(_): true;
                                            default: false;
                                        }
                                    default: false;
                                };

                                if (shouldPreserve) {
                                    #if debug_temp_binding
                                    // DISABLED: trace('[InlineTempBindingInExpr] Preserving case expression - not collapsing');
                                    // DISABLED: trace('[InlineTempBindingInExpr]   tmp      = ' + tmp);
                                    // DISABLED: trace('[InlineTempBindingInExpr]   bindExpr = case expression');
                                    #end
                                    // Return the block unchanged to preserve the case structure
                                    return node; // Return unchanged to preserve pattern matching
                                }

                                var collapsed = replaceVar(second, tmp, bindExpr);
                                #if debug_temp_binding
                                // DISABLED: trace('[InlineTempBindingInExpr] Collapsing temp binding in expression context');
                                // DISABLED: trace('[InlineTempBindingInExpr]   tmp      = ' + tmp);
                                // DISABLED: trace('[InlineTempBindingInExpr]   bindExpr = ' + ElixirASTPrinter.print(bindExpr, 0));
                                // DISABLED: trace('[InlineTempBindingInExpr]   second   = ' + ElixirASTPrinter.print(second, 0));
                                // DISABLED: trace('[InlineTempBindingInExpr]   result   = ' + ElixirASTPrinter.print(collapsed, 0));
                                #end
                                return collapsed;
                            }
                        default:
                    }
                default:
            }
            
            return node;
        });
    }

    /**
     * Clean up redundant temp alias assignments
     * 
     * WHY: Enum extraction can generate redundant temp alias assignments in statement contexts
     * WHAT: Removes temp alias assignments that immediately precede their only usage
     * HOW: Detects `alias = value; use(alias)` patterns and simplifies to `use(value)`
     * 
     * PATTERN:
     * Before: `g_temp = :some_atom; case g_temp do ... end`
     * After: `case :some_atom do ... end`
     */
    public static function tempAliasCleanupPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, cleanupTempAliases);
    }
    
    private static function cleanupTempAliases(node: ElixirAST): ElixirAST {
        switch(node.def) {
            case EBlock(exprs) if (exprs.length >= 2):
                var newExprs = [];
                var i = 0;
                while (i < exprs.length) {
                    // Look for temp alias pattern: g_temp = value followed by immediate use
                    if (i < exprs.length - 1) {
                        switch(exprs[i].def) {
                            case EMatch(PVar(varName), value) if (isTempAliasVar(varName)):
                                // Check if next expression immediately uses this temp var
                                var nextExpr = exprs[i + 1];
                                if (isSingleUseOfVar(nextExpr, varName)) {
                                    // Replace the usage with the value directly
                                    var replaced = replaceVarWithValue(nextExpr, varName, value);
                                    newExprs.push(replaced);
                                    i += 2; // Skip both the assignment and the usage
                                    continue;
                                }
                            default:
                        }
                    }
                    newExprs.push(exprs[i]);
                    i++;
                }
                
                if (newExprs.length != exprs.length) {
                    return makeAST(EBlock(newExprs));
                }
                
            default:
        }
        return node;
    }
    
    private static function isSingleUseOfVar(expr: ElixirAST, varName: String): Bool {
        // Simple check - could be enhanced to verify it's the ONLY use
        return switch(expr.def) {
            case ECase(caseExpr, _):
                switch(caseExpr.def) {
                    case EVar(v) if (v == varName): true;
                    default: false;
                }
            case ECall(_, _, args):
                args.length > 0 && switch(args[0].def) {
                    case EVar(v) if (v == varName): true;
                    default: false;
                }
            default: false;
        };
    }

    private static inline function isTempAliasVar(name: String): Bool {
        if (name == null || name.length == 0) return false;
        // Handle g_*, _g, _g*, g, g1, etc.
        return name.indexOf("g_") == 0 || StringTools.startsWith(name, "_g") || name == "g" || StringTools.startsWith(name, "g");
    }
    
    private static function replaceVarWithValue(expr: ElixirAST, varName: String, value: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(expr, function(n) {
            return switch(n.def) {
                case EVar(v) if (v == varName): value;
                default: n;
            };
        });
    }

    /**
     * Resolve variable references in case clauses
     * 
     * WHY: Variable references in case clauses may use IDs instead of names
     * WHAT: Resolves variable references using varIdToName metadata
     * HOW: Remaps EVar nodes with sourceVarId to their proper names using varIdToName mapping
     * 
     * PATTERN:
     * Before: EVar("temp") with sourceVarId=123 and varIdToName={123 => "user_id"}
     * After: EVar("user_id")
     */
    public static function resolveClauseLocalsPass(ast: ElixirAST): ElixirAST {
        #if debug_clause_locals
        // DISABLED: trace('[XRay ResolveClauseLocals] Starting pass');
        #end
        
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            // Check if this node has varIdToName metadata
            if (node.metadata != null && node.metadata.varIdToName != null) {
                var varIdToName = node.metadata.varIdToName;
                
                #if debug_clause_locals
                // DISABLED: trace('[XRay ResolveClauseLocals] Found varIdToName metadata with ${Lambda.count(varIdToName)} mappings');
                for (id => name in varIdToName) {
                    // DISABLED: trace('  $id -> $name');
                }
                #end
                
                // Transform all EVar nodes within this subtree
                return ElixirASTTransformer.transformNode(node, function(inner: ElixirAST): ElixirAST {
                    switch(inner.def) {
                        case EVar(currentName):
                            // Check if this variable has a sourceVarId that needs remapping
                            if (inner.metadata != null && inner.metadata.sourceVarId != null) {
                                var sourceId = inner.metadata.sourceVarId;
                                if (varIdToName.exists(sourceId)) {
                                    var newName = varIdToName.get(sourceId);
                                    
                                    #if debug_clause_locals
                                    // DISABLED: trace('[XRay ResolveClauseLocals] Remapping variable: $currentName (id:$sourceId) -> $newName');
                                    #end
                                    
                                    // Create new EVar with the mapped name
                                    return makeASTWithMeta(EVar(newName), inner.metadata, inner.pos);
                                }
                            }
                            return inner;
                            
                        default:
                            return inner;
                    }
                });
            }
            
            return node;
        });
    }
    
    /**
     * Inline if temp assignment cleanup pass
     * 
     * WHY: Switch expressions on non-enum types generate temp vars (g, g1, etc.)
     *      that appear as embedded assignments in inline if conditions
     * WHAT: Transforms inline if with embedded temp assignment to direct comparison
     * HOW: Detects if expressions where condition contains temp var assignment and inlines the value
     * 
     * PATTERN:
     * Before: `result = g = msg_type; if (g == "test"), do: a, else: b`
     * After: `result = if (msg_type == "test"), do: a, else: b`
     * 
     * EDGE CASES:
     * - Handles both parenthesized and non-parenthesized assignments
     * - Only transforms genuine temp vars (g, g1, g2, etc.)
     * - Preserves semantics by direct substitution
     */
    public static function inlineIfTempAssignmentPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                // Pattern 1: Block with temp assignment followed by if statement
                case EBlock(exprs) if (exprs.length == 2):
                    switch(exprs[0].def) {
                        case EMatch(PVar(tempVar), value) if (isTempVar(tempVar)):
                            switch(exprs[1].def) {
                                case EIf(condition, thenBranch, elseBranch):
                                    // Check if condition uses the temp var
                                    if (containsTempVar(condition, tempVar)) {
                                        // Replace temp var with value in condition
                                        var newCondition = replaceTempVar(condition, tempVar, value);
                                        #if debug_temp_variable_transforms
                                        // DISABLED: trace('[InlineIfTempAssignment] Transforming block with temp assignment');
                                        // DISABLED: trace('  Temp var: $tempVar');
                                        // DISABLED: trace('  Value: ${ElixirASTPrinter.print(value, 0)}');
                                        // DISABLED: trace('  Old condition: ${ElixirASTPrinter.print(condition, 0)}');
                                        // DISABLED: trace('  New condition: ${ElixirASTPrinter.print(newCondition, 0)}');
                                        #end
                                        return makeAST(EIf(newCondition, thenBranch, elseBranch), node.pos);
                                    }
                                default:
                            }
                        default:
                    }
                
                // Pattern 2: Inline if with assignment directly in condition
                case EIf(condition, thenBranch, elseBranch):
                    switch(condition.def) {
                        // Pattern: (g = value) == something
                        case EBinary(op, left, right):
                            var transformedLeft = switch(left.def) {
                                case EParen(inner):
                                    switch(inner.def) {
                                        case EMatch(PVar(tempVar), value) if (isTempVar(tempVar)):
                                            #if debug_temp_variable_transforms
                                            // DISABLED: trace('[InlineIfTempAssignment] Found parenthesized temp assignment in if condition');
                                            // DISABLED: trace('  Temp var: $tempVar');
                                            // DISABLED: trace('  Value: ${ElixirASTPrinter.print(value, 0)}');
                                            #end
                                            value; // Use the value directly
                                        default:
                                            left;
                                    }
                                case EMatch(PVar(tempVar), value) if (isTempVar(tempVar)):
                                    #if debug_temp_variable_transforms
                                    // DISABLED: trace('[InlineIfTempAssignment] Found temp assignment in if condition');
                                    // DISABLED: trace('  Temp var: $tempVar');
                                    // DISABLED: trace('  Value: ${ElixirASTPrinter.print(value, 0)}');
                                    #end
                                    value; // Use the value directly
                                default:
                                    left;
                            };
                            
                            if (transformedLeft != left) {
                                var newCondition = makeAST(EBinary(op, transformedLeft, right), condition.pos);
                                #if debug_temp_variable_transforms
                                // DISABLED: trace('  New condition: ${ElixirASTPrinter.print(newCondition, 0)}');
                                #end
                                return makeAST(EIf(newCondition, thenBranch, elseBranch), node.pos);
                            }
                        default:
                    }
                    
                default:
            }
            return node;
        });
    }
    
    // Helper to detect temp variables generated by Haxe
    private static function isTempVar(name: String): Bool {
        // Detect g, g1, g2, g_1, etc. patterns
        return ~/^g(_?\d*)?$/.match(name);
    }
    
    // Helper to check if an AST contains a specific temp var
    private static function containsTempVar(ast: ElixirAST, varName: String): Bool {
        var found = false;
        iterateAST(ast, function(n) {
            switch(n.def) {
                case EVar(v) if (v == varName):
                    found = true;
                default:
            }
        });
        return found;
    }
    
    // Helper to replace temp var with value in AST
    private static function replaceTempVar(ast: ElixirAST, varName: String, replacement: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n) {
            return switch(n.def) {
                case EVar(v) if (v == varName):
                    // Wrap in parentheses to preserve precedence
                    makeAST(EParen(replacement), n.pos);
                default:
                    n;
            };
        });
    }
    
    // Helper function to iterate over AST nodes
    private static function iterateAST(node: ElixirAST, visitor: ElixirAST -> Void): Void {
        if (node == null) return;
        
        visitor(node);
        
        switch(node.def) {
            case EBlock(exprs):
                for (e in exprs) iterateAST(e, visitor);
            case ECall(target, method, args):
                iterateAST(target, visitor);
                for (a in args) iterateAST(a, visitor);
            case EMap(pairs):
                for (p in pairs) iterateAST(p.value, visitor);
            case EKeywordList(pairs):
                for (p in pairs) iterateAST(p.value, visitor);
            case ETuple(values):
                for (v in values) iterateAST(v, visitor);
            case EList(items):
                for (i in items) iterateAST(i, visitor);
            case EBinary(op, left, right):
                iterateAST(left, visitor);
                iterateAST(right, visitor);
            case EUnary(op, expr):
                iterateAST(expr, visitor);
            case ECase(expr, clauses):
                iterateAST(expr, visitor);
                for (c in clauses) {
                    if (c.guard != null) iterateAST(c.guard, visitor);
                    iterateAST(c.body, visitor);
                }
            case EIf(cond, thenB, elseB):
                iterateAST(cond, visitor);
                iterateAST(thenB, visitor);
                if (elseB != null) iterateAST(elseB, visitor);
            case ECond(clauses):
                for (c in clauses) {
                    iterateAST(c.condition, visitor);
                    iterateAST(c.body, visitor);
                }
            case EDef(name, args, guards, body):
                if (guards != null) iterateAST(guards, visitor);
                iterateAST(body, visitor);
            case EDefp(name, args, guards, body):
                if (guards != null) iterateAST(guards, visitor);
                iterateAST(body, visitor);
            case EDefmodule(name, body):
                iterateAST(body, visitor);
            case EParen(expr):
                iterateAST(expr, visitor);
            case EMatch(pattern, expr):
                iterateAST(expr, visitor);
            default:
                // Leaf nodes
        }
    }
}

#end
