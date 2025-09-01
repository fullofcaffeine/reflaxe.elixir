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
     * 1. First expression must be an assignment chain (can be nested)
     * 2. Second expression must be a method call or field access
     * 3. The call/access must use the last assigned variable from the chain
     * 
     * EXAMPLES THAT MATCH:
     *   first:  c = index = i = i + 1
     *   second: s.cca(index)
     *   → Matches because 'index' is used in the call
     * 
     *   first:  result = pos = pos + 1
     *   second: array[pos]
     *   → Matches because 'pos' is used in the access
     * 
     * EXAMPLES THAT DON'T MATCH:
     *   first:  c = 5
     *   second: s.cca(unrelated_var)
     *   → Doesn't match because 'unrelated_var' wasn't assigned
     * 
     *   first:  c = d = 10
     *   second: print("hello")
     *   → Doesn't match because print doesn't use 'd'
     * 
     * @param first The first expression (potential assignment chain)
     * @param second The second expression (potential method call)
     * @return True if this is a split inline expansion
     */
    static function isInlineExpansionSplit(first: ElixirAST, second: ElixirAST): Bool {
        // Extract the last assigned variable from the chain
        var lastVar = extractLastAssignedVar(first);
        
        #if debug_inline_combiner
        if (lastVar != null) {
            trace('[XRay InlineCombiner] Last assigned variable: $lastVar');
        }
        #end
        
        if (lastVar == null) return false;
        
        // Check if second is a method call that uses this variable
        return switch(second.def) {
            case ECall(target, methodName, args) if (target != null):
                var uses = usesVariable(args, lastVar);
                #if debug_inline_combiner
                trace('[XRay InlineCombiner] Method call ${methodName} uses ${lastVar}: $uses');
                #end
                uses;
            default:
                false;
        };
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
        
        // Modify the method call to include the assignment chain in its arguments
        var modifiedCall = embedAssignmentInCall(second, restOfChain);
        
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
     * Finds simple variable references in the call arguments and replaces
     * them with the full assignment chain. This ensures the assignments
     * happen as part of evaluating the method arguments.
     * 
     * Example:
     *   call: s.cca(index)
     *   chain: index = i = i + 1
     *   result: s.cca(index = i = i + 1)
     * 
     * @param call The method call to modify
     * @param assignmentChain The assignment chain to embed
     * @return Modified method call with embedded assignments
     */
    static function embedAssignmentInCall(call: ElixirAST, assignmentChain: ElixirAST): ElixirAST {
        return switch(call.def) {
            case ECall(target, methodName, args):
                // Replace simple variable references with the assignment chain
                var newArgs = args.map(function(arg) {
                    return switch(arg.def) {
                        case EVar(name):
                            // Check if this variable appears in the assignment chain
                            var chainVar = extractFirstVar(assignmentChain);
                            if (chainVar == name) {
                                // Replace with the full assignment chain
                                assignmentChain;
                            } else {
                                arg;
                            }
                        default:
                            arg;
                    };
                });
                ElixirASTHelpers.make(ECall(target, methodName, newArgs));
            default:
                call;
        };
    }
}

#end