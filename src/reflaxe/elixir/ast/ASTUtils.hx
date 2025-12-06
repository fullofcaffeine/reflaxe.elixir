package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.EPattern;

/**
 * ASTUtils: Defensive utilities for robust AST transformation and manipulation
 * 
 * WHY: ElixirASTTransformer's pattern matching often fails on unexpected AST structures
 * - Pattern matching in ElixirASTTransformer assumes specific structures that don't always exist
 * - Nested EBlock structures cause Map iterator assignments to remain in transformed code
 * - Hard-to-debug mismatches when AST structure doesn't match expected patterns
 * - Example: mapIteratorTransformPass expected flat blocks but got EBlock([EBlock([exprs])])
 * - Need centralized utilities to handle AST variations gracefully instead of crashing
 * 
 * WHAT: Provides robust AST manipulation utilities with defensive programming
 * - Recursive block flattening for any nesting depth (EBlock inside EBlock inside EBlock...)
 * - Pattern detection with exhaustive traversal (finds patterns anywhere in AST)
 * - Safe expression extraction with graceful fallbacks (never returns null/crashes)
 * - Debug visualization for AST structure analysis (understand what's actually there)
 * - Iterator assignment filtering (removes Map.key_value_iterator() patterns)
 * 
 * HOW: Uses defensive programming and exhaustive pattern matching
 * - flattenBlocks: Recursively unwraps nested EBlock structures into flat array
 * - containsIteratorPattern: Uses transformNode for guaranteed complete traversal
 * - filterIteratorAssignments: Safely removes Map iterator assignments while preserving other code
 * - debugAST: Visualizes AST structure for debugging transformation issues
 * - All functions handle null/undefined gracefully with safe defaults
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on AST manipulation utilities
 * - Open/Closed: Easy to add new utilities without modifying existing
 * - Testability: Pure functions with no side effects (except debug output)
 * - Reusability: Used by multiple transformation passes (Map iteration, loops, patterns)
 * - Defensive: Never crashes on unexpected input, always returns valid output
 * 
 * EDGE CASES HANDLED:
 * - Null AST nodes return empty arrays/false instead of crashing
 * - Deeply nested blocks handled via unbounded recursion
 * - Empty blocks return empty arrays (not null)
 * - Single expressions treated as single-element arrays
 * - Mixed nesting (some blocks nested, others not) handled correctly
 * 
 * HISTORY:
 * - Created in response to Map iterator transformation failures (January 2025)
 * - Extracted from initial attempt to add to ElixirASTTransformer.hx (4000+ lines)
 * - Designed to prevent future "hard-to-debug mismatchers" per user request
 */
@:nullSafety(Off)
class ASTUtils {
    
    /**
     * Walk the AST tree and invoke a visitor on every descendant node.
     *
     * WHY: Some passes need read-only traversal (collecting facts) without
     * depending on private helpers on transformer modules.
     *
     * WHAT: Performs a full traversal using transformNode but returns the
     * original tree unchanged. The visitor is called on every node.
     *
     * HOW: Delegates to ElixirASTTransformer.transformNode to guarantee
     * exhaustive traversal. The transformer callback returns the node
     * unmodified and invokes the visitor for side effects.
     */
    public static function walk(ast: ElixirAST, visitor: ElixirAST -> Void): Void {
        if (ast == null || ast.def == null) return;
        ElixirASTTransformer.transformNode(ast, function(n) {
            visitor(n);
            return n;
        });
    }
    
    /**
     * Recursively flatten nested EBlock structures into a single array of expressions
     * 
     * WHY: AST often contains arbitrary nesting of blocks that breaks pattern matching
     * - Generator creates EBlock([EBlock([exprs])]) when we expect EBlock([exprs])
     * - Pattern matching fails when nesting depth doesn't match expectations
     * - Need to normalize to flat list regardless of original nesting
     * 
     * WHAT: Converts any level of nested blocks into a flat array
     * - Handles unlimited nesting depth (recursive approach)
     * - Preserves expression order (depth-first traversal)
     * - Returns empty array for null/invalid input (defensive)
     * 
     * HOW: Recursive descent through EBlock structures
     * - If node is EBlock, recursively flatten its children
     * - If node is not EBlock, return it as single-element array
     * - Concatenate results to build flat list
     * 
     * Example:
     *   EBlock([EBlock([expr1, expr2]), expr3]) -> [expr1, expr2, expr3]
     *   EBlock([EBlock([EBlock([expr1])])]) -> [expr1]
     *   null -> []
     */
    public static function flattenBlocks(ast: ElixirAST): Array<ElixirAST> {
        if (ast == null || ast.def == null) return [];
        
        return switch(ast.def) {
            case EBlock(exprs):
                // Recursively flatten any nested blocks
                var flattened = [];
                for (expr in exprs) {
                    flattened = flattened.concat(flattenBlocks(expr));
                }
                flattened;
            default:
                // Non-block expressions return as single-element array
                [ast];
        }
    }
    
    /**
     * Extract expressions from various block structures with safe fallbacks
     * 
     * WHY: Different parts of the compiler create blocks with varying structures
     * - Sometimes we get EBlock([exprs...])  
     * - Sometimes we get EBlock([EBlock([exprs...])])  (single nested block)
     * - Sometimes we get a single expression not wrapped in a block
     * - Need consistent extraction that handles all cases
     * 
     * WHAT: Safely extracts expressions with one-level unwrapping
     * - Unwraps single nested blocks (common pattern)
     * - Preserves multiple expressions as-is
     * - Converts single expressions to arrays
     * - Returns empty array for null (never crashes)
     * 
     * HOW: Pattern matching with special case for single nested block
     * - Check if EBlock contains exactly one element that is also EBlock
     * - If so, unwrap that single nested block
     * - Otherwise return expressions as-is
     * - Non-blocks become single-element arrays
     * 
     * Unlike flattenBlocks, this only unwraps ONE level of nesting
     * Use when you need to preserve some block structure
     */
    public static function extractBlockExprs(ast: ElixirAST): Array<ElixirAST> {
        if (ast == null || ast.def == null) return [];
        
        return switch(ast.def) {
            case EBlock(exprs):
                // Check for single nested block (common AST pattern)
                if (exprs.length == 1) {
                    switch(exprs[0].def) {
                        case EBlock(nested):
                            // Unwrap single nested block
                            nested;
                        default:
                            exprs;
                    }
                } else {
                    exprs;
                }
            default:
                // Single expression becomes array
                [ast];
        }
    }
    
    /**
     * Check if an AST node contains Map iterator patterns anywhere in its tree
     * 
     * WHY: Map iterator code needs to be detected and transformed/removed
     * - Haxe generates .key_value_iterator().next().key patterns
     * - These don't exist in Elixir and must be transformed
     * - Need reliable detection that finds patterns anywhere in AST
     * - Manual traversal often misses nested occurrences
     * 
     * WHAT: Exhaustively detects iterator-related field accesses
     * - Finds: key_value_iterator, has_next, next, key, value
     * - Searches entire AST tree, not just top level
     * - Returns true if ANY iterator pattern found
     * - Works on fields and method calls
     * 
     * HOW: Leverages ElixirASTTransformer.transformNode for guaranteed traversal
     * - transformNode visits every single node in the tree
     * - We use it as a visitor pattern, not for transformation
     * - Set flag when pattern detected, return node unchanged
     * - This ensures we never miss deeply nested patterns
     * 
     * Patterns detected:
     * - colors.key_value_iterator()
     * - iterator.has_next()
     * - iterator.next()
     * - pair.key
     * - pair.value
     */
    public static function containsIteratorPattern(ast: ElixirAST): Bool {
        if (ast == null || ast.def == null) return false;
        
        var hasPattern = false;
        
        // Use transformNode for exhaustive traversal
        ElixirASTTransformer.transformNode(ast, function(n) {
            switch(n.def) {
                case EField(_, field):
                    if (field == "key_value_iterator" || field == "has_next" || 
                        field == "next" || field == "key" || field == "value") {
                        hasPattern = true;
                    }
                case ECall(func, _, _):
                    // Check for calls to iterator methods
                    switch(func.def) {
                        case EField(_, field):
                            if (field == "key_value_iterator" || field == "has_next" || field == "next") {
                                hasPattern = true;
                            }
                        default:
                    }
                default:
            }
            return n; // Return unchanged, we're just detecting
        });
        
        return hasPattern;
    }
    
    /**
     * Filter out Map iterator-related assignments from expression list
     * 
     * WHY: Map iteration transformation leaves orphaned iterator assignments
     * - After transforming to Enum.each, old assignments remain
     * - Example: `name = colors.key_value_iterator().next().key` should be removed
     * - These assignments are invalid Elixir and cause compilation errors
     * - Need selective removal that preserves legitimate code
     * 
     * WHAT: Removes only iterator-related variable assignments
     * - Filters assignments where RHS contains iterator patterns
     * - Preserves all other expressions unchanged
     * - Safe for empty or null input
     * - Returns new filtered array (immutable)
     * 
     * HOW: Iterate and check each expression for iterator patterns
     * - Match on EMatch(PVar(_), rhs) for assignments
     * - Use containsIteratorPattern to check RHS
     * - Skip assignments with iterator patterns
     * - Keep everything else
     * 
     * Removes patterns like:
     * - name = colors.key_value_iterator().next().key
     * - hex = colors.key_value_iterator().next().value
     * - iter = map.key_value_iterator()
     * 
     * Preserves:
     * - Log.trace(...)
     * - Regular assignments without iterator patterns
     * - Function calls, conditionals, etc.
     */
    public static function filterIteratorAssignments(exprs: Array<ElixirAST>): Array<ElixirAST> {
        if (exprs == null) return [];
        
        var filtered = [];
        for (expr in exprs) {
            var skip = false;
            
            switch(expr.def) {
                case EMatch(PVar(_), rhs):
                    // Skip if RHS contains iterator patterns
                    if (containsIteratorPattern(rhs)) {
                        skip = true;
                    }
                default:
                    // Keep non-assignment expressions
            }
            
            if (!skip) {
                filtered.push(expr);
            }
        }
        
        return filtered;
    }
    
    /**
     * Extract field chain from nested field access patterns
     * 
     * WHY: Need to understand complex field/method chains for transformation
     * - Iterator patterns involve chains like obj.method1().method2().field
     * - Transformation logic needs to know what methods are being called
     * - Helps identify iterator patterns vs other field access
     * 
     * WHAT: Extracts field/method names from nested access chains
     * - Returns names in reverse order (innermost first)
     * - Handles both field access and method calls
     * - Returns empty array for non-field expressions
     * 
     * HOW: Walk up the chain from innermost to outermost
     * - Start with given AST node
     * - If it's EField, extract field name and recurse on object
     * - If it's ECall, recurse on function being called
     * - Stop when we hit a non-field/call node
     * 
     * Example:
     *   colors.key_value_iterator().next().key
     *   Returns: ["key", "next", "key_value_iterator"]
     * 
     * This reverse order makes it easy to check if chain ends with
     * specific patterns like ["key", "next", ...]
     */
    public static function extractFieldChain(ast: ElixirAST): Array<String> {
        var fieldChain = [];
        var current = ast;
        
        while (current != null) {
            switch(current.def) {
                case EField(obj, field):
                    fieldChain.push(field);
                    current = obj;
                case ECall(func, _, _):
                    current = func;
                default:
                    current = null;
            }
        }
        
        return fieldChain;
    }
    
    #if debug_ast_structure
    /**
     * Debug utility to visualize AST structure for diagnosing transformation issues
     * 
     * WHY: AST structure mismatches are the #1 cause of transformation failures
     * - Pattern matching expects specific structure but gets something else
     * - Hard to understand actual AST structure from debugger/traces
     * - Need visual representation to see nesting, node types, and values
     * - Example: Seeing EBlock([EBlock([...])]) vs EBlock([...]) visually
     * 
     * WHAT: Pretty-prints AST structure with indentation and details
     * - Shows node types (EVar, EBlock, ECall, etc.)
     * - Displays key values (variable names, field names, etc.)
     * - Indents to show nesting structure
     * - Limits depth to prevent overwhelming output
     * - Only active with -D debug_ast_structure flag
     * 
     * HOW: Recursive tree traversal with formatted output
     * - Use Type.enumConstructor to get node type name
     * - Switch on node type to extract relevant details
     * - Recursively print children with increased indentation
     * - Stop at maxDepth to control output size
     * 
     * Usage: 
     *   #if debug_ast_structure
     *   ASTUtils.debugAST(ast, 0, 5);  // Show 5 levels deep
     *   #end
     * 
     * Example output:
     *   EBlock
     *     exprs: 2
     *     EMatch
     *       pattern: PVar(name)
     *       expr:
     *         ECall
     *           func: key_value_iterator
     *           args: 0
     */
    public static function debugAST(ast: ElixirAST, depth: Int = 0, maxDepth: Int = 5): Void {
        if (ast == null || ast.def == null || depth > maxDepth) return;
        
        var indent = [for (i in 0...depth) "  "].join("");
        var nodeType = Type.enumConstructor(ast.def);
        
        // DISABLED: trace('$indent$nodeType');
        
        // Show key details for specific node types
        switch(ast.def) {
            case EVar(name):
                // DISABLED: trace('$indent  name: $name');
            case EField(_, field):
                // DISABLED: trace('$indent  field: $field');
            case ERemoteCall(_, func, args):
                // DISABLED: trace('$indent  func: $func, args: ${args.length}');
            case EBlock(exprs):
                // DISABLED: trace('$indent  exprs: ${exprs.length}');
                for (expr in exprs) {
                    debugAST(expr, depth + 1, maxDepth);
                }
            case EIf(cond, then, else_):
                // DISABLED: trace('$indent  condition:');
                debugAST(cond, depth + 1, maxDepth);
                // DISABLED: trace('$indent  then:');
                debugAST(then, depth + 1, maxDepth);
                if (else_ != null) {
                    // DISABLED: trace('$indent  else:');
                    debugAST(else_, depth + 1, maxDepth);
                }
            case EMatch(pattern, expr):
                // DISABLED: trace('$indent  pattern: ${pattern}');
                // DISABLED: trace('$indent  expr:');
                debugAST(expr, depth + 1, maxDepth);
            case EFn(clauses):
                for (i in 0...clauses.length) {
                    // DISABLED: trace('$indent  clause $i:');
                    debugAST(clauses[i].body, depth + 1, maxDepth);
                }
            case ETuple(elements):
                // DISABLED: trace('$indent  elements: ${elements.length}');
                for (elem in elements) {
                    debugAST(elem, depth + 1, maxDepth);
                }
            case EList(elements):
                // DISABLED: trace('$indent  elements: ${elements.length}');
                for (elem in elements) {
                    debugAST(elem, depth + 1, maxDepth);
                }
            case ERemoteCall(mod, func, args):
                // DISABLED: trace('$indent  module:');
                debugAST(mod, depth + 1, maxDepth);
                // DISABLED: trace('$indent  args: ${args.length}');
            default:
                // Show basic info for other types
        }
    }
    #end
    
    /**
     * Create a simple ElixirAST node with the given definition
     * 
     * WHY: AST node creation is verbose and repetitive
     * - Every node needs def, pos, and metadata fields
     * - Easy to forget to initialize metadata = {}
     * - Repetitive boilerplate throughout transformation code
     * 
     * WHAT: Convenience wrapper for AST node creation
     * - Creates properly initialized AST node
     * - Sets empty metadata by default
     * - Optional position for error reporting
     * - Inline for zero overhead
     * 
     * HOW: Simple factory function
     * - Takes ElixirASTDef as primary parameter
     * - Optional position for source mapping
     * - Returns complete ElixirAST structure
     * 
     * Usage:
     *   makeAST(EVar("x"))  // Simple variable node
     *   makeAST(EBlock([...]), expr.pos)  // With position
     */
    public static inline function makeAST(def: ElixirASTDef, ?pos: haxe.macro.Expr.Position): ElixirAST {
        return {
            def: def,
            pos: pos,
            metadata: {}
        };
    }
}

#end
