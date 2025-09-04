package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTHelpers;

/**
 * InlineExpansionTransforms: Fixes for Haxe's inline expansion patterns
 * 
 * WHY THIS CLASS EXISTS:
 * Haxe's inline expansion mechanism creates semantic mismatches with Elixir's expression model.
 * When Haxe inlines functions (especially standard library functions marked `extern inline`),
 * it transforms the code to ensure correct evaluation order. This creates patterns that are
 * valid in Haxe but generate invalid Elixir code.
 * 
 * WHAT THIS CLASS DOES:
 * Provides transformation passes that detect and fix inline expansion patterns:
 * - Split method calls: When assignments are separated from their values
 * - Evaluation order issues: When Haxe's safety transformations create invalid Elixir
 * - Block implicit returns: When Haxe relies on block return values that Elixir doesn't support
 * 
 * HOW IT WORKS:
 * Each transformation pass:
 * 1. Detects specific inline expansion patterns in the AST
 * 2. Analyzes the semantic intent of the original code
 * 3. Transforms to idiomatic Elixir that preserves semantics
 * 
 * SOLUTION IMPLEMENTED (September 2025):
 * - Fixed indentation in lambda bodies (EFn case in ElixirASTPrinter)
 * - Improved pattern detection to check all variables in assignment chains
 * - Fixed variable replacement logic to correctly embed assignment chains in method calls
 * - Successfully combines patterns like: index = i = i + 1; s.cca(index) → index = s.cca(i = i + 1)
 * 
 * REMAINING ISSUE:
 * - Assignments embedded in binary operations (e.g., expr1 ||| index = call() &&& expr2)
 *   generate invalid Elixir because assignments cannot appear inside arithmetic expressions.
 *   Solution requires extracting assignments before the expression that uses them.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles inline expansion issues
 * - Testability: Each pattern can be tested in isolation
 * - Maintainability: New patterns can be added without affecting others
 * - Debuggability: XRay traces show exactly what's being transformed
 * 
 * @see https://github.com/HaxeFoundation/haxe/wiki/Inline-Functions
 * @see docs/03-compiler-development/INLINE_EXPANSION_PATTERNS.md
 */
class InlineExpansionTransforms {
    
    /**
     * Inline Method Call Combiner Pass
     * 
     * THE PROBLEM:
     * When Haxe inlines a method like `s.charCodeAt(index = i = i + 1)`, it must ensure
     * the assignments happen before the method call. Haxe generates:
     * 
     *   TBlock([
     *     TBinop(OpAssign, c, TBinop(OpAssign, index, TBinop(OpAssign, i, TBinop(OpAdd, i, 1)))),
     *     TCall(TField(s, "cca"), [TLocal(index)])
     *   ])
     * 
     * This becomes Elixir AST:
     *   EBlock([
     *     EMatch(PVar("c"), EBinary(Match, EVar("index"), EBinary(Match, EVar("i"), EBinary(Add, EVar("i"), EInteger(1))))),
     *     ECall(EField(EVar("s"), "cca"), [EVar("index")])
     *   ])
     * 
     * Which generates invalid Elixir:
     *   c = index = i = i + 1
     *   s.cca(index)           # Standalone expression - syntax error!
     * 
     * THE SOLUTION:
     * Combine the split expressions into valid Elixir:
     *   c = s.cca(index = i = i + 1)
     * 
     * This preserves:
     * - Evaluation order (assignments happen first)
     * - Side effects (i is incremented)
     * - Return value (c gets the method result)
     * 
     * PATTERN DETECTION:
     * We look for EBlock with exactly 2 expressions where:
     * 1. First is an assignment chain ending with a variable
     * 2. Second is a method call using that variable
     * 3. The call is the intended value for the first assignment
     * 
     * REAL-WORLD EXAMPLES:
     * - String.charCodeAt with index increment
     * - Array access with position update
     * - Iterator next() with counter advance
     * 
     * @param ast The AST to transform
     * @return Transformed AST with combined inline expansions
     */
    public static function inlineMethodCallCombinerPass(ast: ElixirAST): ElixirAST {
        #if debug_inline_combiner
        trace('[XRay InlineCombiner] Starting inline method call combiner pass');
        #end
        
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            #if debug_inline_combiner_verbose
            // Log every node type we visit
            switch(node.def) {
                case EBlock(exprs): 
                    trace('[XRay InlineCombiner] Visiting EBlock with ${exprs.length} expressions');
                case EIf(_, _, _):
                    trace('[XRay InlineCombiner] Visiting EIf');
                case ELambda(_, body):
                    trace('[XRay InlineCombiner] Visiting ELambda with body: ${body.def}');
                default:
            }
            #end
            
            switch(node.def) {
                case EBlock([first, second]):
                    #if debug_inline_combiner
                    trace('[XRay InlineCombiner] Found 2-expression block');
                    trace('[XRay InlineCombiner]   First: ${first.def}');
                    trace('[XRay InlineCombiner]   Second: ${second.def}');
                    #end
                    
                    // Check if this matches the inline expansion split pattern
                    if (isInlineExpansionSplit(first, second)) {
                        #if debug_inline_combiner
                        trace('[XRay InlineCombiner] ✓ Pattern detected - combining expressions');
                        #end
                        return combineInlineExpansion(first, second);
                    }
                    
                // Also check blocks with more than 2 expressions where 
                // consecutive expressions might need combining
                case EBlock(exprs) if (exprs.length > 2):
                    #if debug_inline_combiner
                    trace('[XRay InlineCombiner] Checking block with ${exprs.length} expressions for inline patterns');
                    #end
                    
                    var modified = false;
                    var newExprs = [];
                    var i = 0;
                    while (i < exprs.length) {
                        if (i < exprs.length - 1) {
                            var first = exprs[i];
                            var second = exprs[i + 1];
                            
                            #if debug_inline_combiner
                            trace('[XRay InlineCombiner] Checking pair at index $i:');
                            trace('[XRay InlineCombiner]   First: ${first.def}');  
                            trace('[XRay InlineCombiner]   Second: ${second.def}');
                            #end
                            
                            if (isInlineExpansionSplit(first, second)) {
                                #if debug_inline_combiner
                                trace('[XRay InlineCombiner] ✓ Found inline pattern in larger block at index $i');
                                #end
                                var combined = combineInlineExpansion(first, second);
                                newExprs.push(combined);
                                modified = true;
                                i += 2; // Skip both expressions since we combined them
                            } else {
                                newExprs.push(first);
                                i++;
                            }
                        } else {
                            newExprs.push(exprs[i]);
                            i++;
                        }
                    }
                    
                    if (modified) {
                        #if debug_inline_combiner
                        trace('[XRay InlineCombiner] Modified block from ${exprs.length} to ${newExprs.length} expressions');
                        #end
                        return ElixirASTHelpers.make(EBlock(newExprs));
                    }
                    
                default:
                    // Not a block or single expression block, continue traversal
            }
            return node;
        });
    }
    
    /**
     * Checks if two expressions match the inline expansion split pattern
     * 
     * PATTERN REQUIREMENTS:
     * 1. First expression must be an assignment chain (can be nested) with MULTIPLE assignments
     *    OR an assignment with arithmetic operations
     * 2. Second expression must be a method call or field access
     * 3. The call/access must use ANY variable from the assignment chain
     * 4. The assignment MUST be part of a chain or arithmetic pattern, not a simple assignment
     * 
     * EXAMPLES THAT MATCH:
     *   first:  c = index = i = i + 1
     *   second: s.cca(index)
     *   → Matches because 'index' is used and there's a chain with arithmetic
     * 
     *   first:  result = pos = pos + 1
     *   second: array[pos]
     *   → Matches because 'pos' is used and there's a chain with arithmetic
     * 
     * EXAMPLES THAT DON'T MATCH:
     *   first:  editing_badge = if(condition, "value1", "value2")
     *   second: push("..." <> editing_badge <> "...")
     *   → Doesn't match because it's a simple assignment (not a chain)
     * 
     *   first:  c = 5
     *   second: s.cca(c)
     *   → Doesn't match because it's a simple assignment
     * 
     *   first:  c = d = 10
     *   second: print("hello")
     *   → Doesn't match because print doesn't use 'c' or 'd'
     * 
     * @param first The first expression (potential assignment chain)
     * @param second The second expression (potential method call)
     * @return True if this is a split inline expansion
     */
    static function isInlineExpansionSplit(first: ElixirAST, second: ElixirAST): Bool {
        // Check if this is actually an assignment chain with multiple assignments
        // or involves arithmetic operations that need special handling
        if (!isComplexAssignmentChain(first)) {
            #if debug_inline_combiner
            trace('[XRay InlineCombiner] Not a complex assignment chain - skipping');
            #end
            return false;
        }
        // Extract ALL variables from the assignment chain
        var assignedVars = extractAllAssignedVars(first);
        
        #if debug_inline_combiner
        if (assignedVars.length > 0) {
            trace('[XRay InlineCombiner] Assignment chain variables: ${assignedVars.join(", ")}');
        }
        #end
        
        if (assignedVars.length == 0) return false;
        
        // Check if second is a method call that uses ANY of these variables
        return switch(second.def) {
            case ECall(target, methodName, args):
                // Note: target can be null for local function calls
                // Check if any of the assigned variables are used in the call
                var uses = false;
                for (varName in assignedVars) {
                    if (usesVariable(args, varName)) {
                        uses = true;
                        #if debug_inline_combiner
                        trace('[XRay InlineCombiner] Method call ${methodName} uses ${varName}: true');
                        #end
                        break;
                    }
                }
                #if debug_inline_combiner
                if (!uses && methodName != null) {
                    trace('[XRay InlineCombiner] Method call ${methodName} uses none of [${assignedVars.join(", ")}]');
                }
                #end
                uses;
            case EField(target, fieldName):
                // Handle field access that might be a method call (e.g., s.cca)
                #if debug_inline_combiner
                trace('[XRay InlineCombiner] Found field access: ${fieldName} - not a direct call');
                #end
                false;
            default:
                #if debug_inline_combiner
                trace('[XRay InlineCombiner] Second expression is not a call: ${second.def}');
                #end
                false;
        };
    }
    
    /**
     * Checks if an expression is a complex assignment chain that needs special handling
     * 
     * WHAT QUALIFIES AS COMPLEX:
     * - Multiple chained assignments: a = b = c + 1
     * - Assignments with arithmetic: i = i + 1
     * - Nested assignment chains
     * 
     * WHAT DOESN'T QUALIFY:
     * - Simple assignments: a = value
     * - Ternary/if assignments: a = if(cond, val1, val2)
     * - Function call assignments: a = func()
     * 
     * @param expr The expression to check
     * @return True if this is a complex assignment chain needing inline expansion
     */
    static function isComplexAssignmentChain(expr: ElixirAST): Bool {
        return switch(expr.def) {
            case EMatch(_, right):
                // Check if the right side is another assignment or arithmetic
                switch(right.def) {
                    case EBinary(Match, _, _): true; // Chained assignment
                    case EBinary(Add | Subtract | Multiply | Divide, _, _): true; // Arithmetic
                    default: false;
                }
            case EBinary(Match, _, right):
                // Binary match - check if right is complex
                switch(right.def) {
                    case EBinary(Match, _, _): true; // Chained assignment
                    case EBinary(Add | Subtract | Multiply | Divide, _, _): true; // Arithmetic
                    default: false;
                }
            default:
                false;
        };
    }
    
    /**
     * Extracts ALL assigned variables from an assignment chain
     * 
     * ALGORITHM:
     * Collects all variables that appear on the left side of assignments
     * in the chain. For `c = index = i = i + 1`, returns ["c", "index", "i"]
     * 
     * @param expr The expression to analyze
     * @return Array of all assigned variable names in the chain
     */
    static function extractAllAssignedVars(expr: ElixirAST): Array<String> {
        var vars = [];
        
        function collectVars(e: ElixirAST): Void {
            switch(e.def) {
                case EMatch(PVar(name), right):
                    // Pattern match assignment: name = right
                    vars.push(name);
                    collectVars(right);
                    
                case EBinary(Match, left, right):
                    // Binary match operation: left = right
                    switch(left.def) {
                        case EVar(name): 
                            vars.push(name);
                        default:
                    }
                    collectVars(right);
                    
                case EBinary(Add | Subtract | Multiply | Divide, left, _):
                    // Arithmetic operations: check left side for variables
                    switch(left.def) {
                        case EVar(name): 
                            vars.push(name);
                        default:
                            collectVars(left);
                    }
                    
                default:
                    // Not an assignment
            }
        }
        
        collectVars(expr);
        return vars;
    }
    
    /**
     * Extracts the last assigned variable from an assignment chain
     * 
     * ALGORITHM:
     * Recursively traverses the assignment chain from left to right,
     * finding the deepest assigned variable. This handles:
     * - Simple assignments: c = 5 → "c"
     * - Chained assignments: c = d = 5 → "d"
     * - Arithmetic in assignments: c = i = i + 1 → "i" (from i + 1)
     * 
     * SPECIAL CASES:
     * - Increment operations: i = i + 1 → returns "i"
     * - Complex expressions: a = b = func() → returns "b"
     * - Non-assignments: 5 + 3 → returns null
     * 
     * @param expr The expression to analyze
     * @return The name of the last assigned variable, or null
     */
    static function extractLastAssignedVar(expr: ElixirAST): Null<String> {
        return switch(expr.def) {
            case EMatch(PVar(name), right):
                // Pattern match assignment: name = right
                // Check if right side contains more assignments
                var rightVar = extractLastAssignedVar(right);
                rightVar != null ? rightVar : name;
                
            case EBinary(Match, left, right):
                // Binary match operation: left = right
                // First check right side for nested assignments
                var rightVar = extractLastAssignedVar(right);
                if (rightVar != null) return rightVar;
                
                // If no assignment in right, check if left is a variable
                switch(left.def) {
                    case EVar(name): name;
                    default: null;
                }
                
            case EBinary(Add | Subtract | Multiply | Divide, left, _):
                // Arithmetic operations: often contain the variable being updated
                // e.g., i + 1 where we want to extract 'i'
                switch(left.def) {
                    case EVar(name): name;
                    default: extractLastAssignedVar(left);
                }
                
            default:
                null;
        };
    }
    
    /**
     * Checks if any argument in the list uses the specified variable
     * 
     * @param args List of arguments to check
     * @param varName Variable name to search for
     * @return True if any argument contains the variable
     */
    static function usesVariable(args: Array<ElixirAST>, varName: String): Bool {
        for (arg in args) {
            if (containsVariable(arg, varName)) return true;
        }
        return false;
    }
    
    /**
     * Recursively checks if an expression contains a specific variable
     * 
     * TRAVERSAL STRATEGY:
     * - Direct variable references: EVar("name")
     * - Binary operations: Check both sides
     * - Function calls: Check target and arguments
     * - Collections: Check all elements
     * - Pattern matches: Check the value side
     * 
     * @param expr Expression to search
     * @param varName Variable name to find
     * @return True if the variable appears anywhere in the expression
     */
    static function containsVariable(expr: ElixirAST, varName: String): Bool {
        return switch(expr.def) {
            case EVar(name):
                name == varName;
                
            case EBinary(_, left, right):
                containsVariable(left, varName) || containsVariable(right, varName);
                
            case EMatch(_, value):
                containsVariable(value, varName);
                
            case ECall(target, _, args):
                (target != null && containsVariable(target, varName)) ||
                usesVariable(args, varName);
                
            case EList(elements) | ETuple(elements):
                usesVariable(elements, varName);
                
            case EField(target, _):
                containsVariable(target, varName);
                
            case EMap(pairs):
                for (pair in pairs) {
                    if (containsVariable(pair.key, varName) || 
                        containsVariable(pair.value, varName)) {
                        return true;
                    }
                }
                false;
                
            default:
                false;
        };
    }
    
    /**
     * Combines the split inline expansion into a single valid expression
     * 
     * TRANSFORMATION STRATEGY:
     * Given:
     *   first:  c = index = i = i + 1
     *   second: s.cca(index)
     * 
     * Steps:
     * 1. Extract 'c' (the ultimate target of the assignment)
     * 2. Extract 'index = i = i + 1' (the rest of the chain)
     * 3. Replace 'index' in s.cca(index) with 'index = i = i + 1'
     * 4. Create final: c = s.cca(index = i = i + 1)
     * 
     * This ensures:
     * - 'i' is incremented before the method call
     * - 'index' gets the new value of 'i'
     * - The method uses the updated 'index'
     * - 'c' receives the method's return value
     * 
     * @param first The assignment chain expression
     * @param second The method call expression
     * @return Combined expression that's valid in Elixir
     */
    static function combineInlineExpansion(first: ElixirAST, second: ElixirAST): ElixirAST {
        // Extract the first variable from the assignment chain
        var firstVar = extractFirstVar(first);
        
        #if debug_inline_combiner
        trace('[XRay InlineCombiner] First variable in chain: $firstVar');
        #end
        
        if (firstVar == null) {
            // Safety fallback - shouldn't happen if isInlineExpansionSplit returned true
            return ElixirASTHelpers.make(EBlock([first, second]));
        }
        
        // Extract the rest of the assignment chain (everything after first var)
        var restOfChain = extractRestOfAssignmentChain(first);
        
        // The key insight: if the method call uses the first variable from the chain,
        // we should replace it with the rest of the chain
        var modifiedCall = embedAssignmentInCall(second, restOfChain, firstVar);
        
        // Create the final assignment: firstVar = modifiedCall
        var result = ElixirASTHelpers.make(EMatch(PVar(firstVar), modifiedCall));
        
        #if debug_inline_combiner
        trace('[XRay InlineCombiner] Combined result: ${result.def}');
        #end
        
        return result;
    }
    
    /**
     * Extracts the first variable from an assignment chain
     * 
     * This is the variable that should receive the final value.
     * 
     * Examples:
     *   c = 5                    → "c"
     *   c = index = 5            → "c"
     *   c = index = i = i + 1    → "c"
     * 
     * @param expr The assignment chain
     * @return The first variable name, or null
     */
    static function extractFirstVar(expr: ElixirAST): Null<String> {
        return switch(expr.def) {
            case EMatch(PVar(name), _):
                name;
            case EBinary(Match, {def: EVar(name)}, _):
                name;
            default:
                null;
        };
    }
    
    /**
     * Extracts everything after the first assignment in a chain
     * 
     * This is what needs to be embedded in the method call.
     * 
     * Examples:
     *   c = 5                    → 5
     *   c = index = 5            → index = 5
     *   c = index = i = i + 1    → index = i = i + 1
     * 
     * @param expr The assignment chain
     * @return The rest of the chain after the first variable
     */
    static function extractRestOfAssignmentChain(expr: ElixirAST): ElixirAST {
        return switch(expr.def) {
            case EMatch(PVar(_), right):
                right;
            case EBinary(Match, _, right):
                right;
            default:
                expr;
        };
    }
    
    /**
     * Embeds an assignment chain into a method call's arguments
     * 
     * REPLACEMENT STRATEGY:
     * Replaces the firstVar (from the original assignment chain) with the restOfChain
     * in the method call arguments.
     * 
     * Example:
     *   Original: index = i = i + 1; s.cca(index)
     *   call: s.cca(index)
     *   assignmentChain: i = i + 1 (the rest after "index =")
     *   firstVar: "index"
     *   
     * We replace "index" in the call with "i = i + 1"
     * to produce: s.cca(i = i + 1)
     * 
     * Then the outer assignment is added: index = s.cca(i = i + 1)
     * 
     * @param call The method call to modify
     * @param assignmentChain The assignment chain to embed (rest of chain after first var)
     * @param firstVar The variable from the original chain that should be replaced
     * @return Modified method call with embedded assignments
     */
    static function embedAssignmentInCall(call: ElixirAST, assignmentChain: ElixirAST, firstVar: String): ElixirAST {
        return switch(call.def) {
            case ECall(target, methodName, args):
                #if debug_inline_combiner
                trace('[XRay InlineCombiner] Looking to replace $firstVar with: ${assignmentChain.def}');
                #end
                
                // Replace the firstVar argument with the assignment chain
                var modified = false;
                var newArgs = args.map(function(arg) {
                    return switch(arg.def) {
                        case EVar(name):
                            // Replace if this is the first variable from the original chain
                            if (name == firstVar) {
                                #if debug_inline_combiner
                                trace('[XRay InlineCombiner] Replacing argument $name with assignment chain');
                                #end
                                modified = true;
                                assignmentChain;
                            } else {
                                arg;
                            }
                        default:
                            arg;
                    };
                });
                
                if (modified) {
                    ElixirASTHelpers.make(ECall(target, methodName, newArgs));
                } else {
                    // No modification needed - return original call
                    call;
                }
            default:
                call;
        };
    }
    
    /**
     * Extracts the first variable from an assignment chain
     * 
     * For "index = i = i + 1", returns "index"
     * For "i = i + 1", returns "i"
     * For non-assignment expressions, returns null
     * 
     * @param expr The assignment chain or expression
     * @return The first variable being assigned, or null if not an assignment
     */
    static function extractFirstVarFromChain(expr: ElixirAST): Null<String> {
        return switch(expr.def) {
            case EMatch(PVar(name), _):
                // Pattern match assignment: name = ...
                name;
            case EBinary(Match, {def: EVar(name)}, _):
                // Binary match: name = ...
                name;
            default:
                // Not an assignment chain - no variable to extract
                null;
        };
    }
}

#end