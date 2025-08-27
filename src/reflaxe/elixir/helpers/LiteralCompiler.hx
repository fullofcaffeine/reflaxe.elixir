package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;import haxe.macro.Type.TConstant;
import reflaxe.elixir.ElixirCompiler;import haxe.macro.Expr;
import reflaxe.elixir.ElixirCompiler;import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * Literal Compiler for Reflaxe.Elixir
 * 
 * WHY: The compileElixirExpressionInternal function contained ~150 lines of literal value compilation
 * scattered throughout TConst handling and string escaping logic. This violated Single Responsibility
 * Principle and made literal compilation hard to test and maintain independently.
 * 
 * WHAT: Specialized compiler for all constant literal values in Haxe-to-Elixir transpilation:
 * - Integer literals (TInt) → Elixir integers
 * - Float literals (TFloat) → Elixir floats  
 * - String literals (TString) → Properly escaped Elixir strings
 * - Boolean literals (TBool) → Elixir atoms (true/false)
 * - Null literals (TNull) → Elixir nil atom
 * - This references (TThis) → Context-sensitive mapping (struct, __MODULE__, etc.)
 * - Super references (TSuper) → Exception handling (Elixir has no inheritance)
 * - String escaping utilities for safe string literal generation
 * 
 * HOW: The compiler implements clean literal transformation patterns:
 * 1. Receives TConstant from ExpressionDispatcher
 * 2. Pattern matches on constant type using exhaustive switch
 * 3. Applies proper Elixir literal formatting and escaping
 * 4. Returns compiled Elixir literal string
 * 5. Provides reusable string escaping utilities for other compilers
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on literal value compilation
 * - Reusability: String escaping functions used by multiple expression types
 * - Type Safety: Exhaustive pattern matching ensures all literal types handled
 * - Testability: Easy to unit test literal transformation logic
 * - Maintainability: Clear separation from expression logic
 * 
 * EDGE CASES:
 * - TThis context mapping through currentFunctionParameterMap
 * - TSuper handled as exception since Elixir lacks inheritance
 * - String escaping handles all common escape sequences
 * - Unknown constants fall back to nil generation
 * 
 * @see documentation/LITERAL_COMPILATION_PATTERNS.md - Complete literal transformation patterns
 */
@:nullSafety(Off)
class LiteralCompiler {
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    
    /**
     * Create a new literal compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Compile TConstant literal values to Elixir equivalents
     * 
     * WHY: Central entry point for all literal compilation replacing scattered TConst logic
     * 
     * WHAT: Transforms Haxe constant literals to properly formatted Elixir literals
     * 
     * HOW:
     * 1. Pattern match on TConstant type using exhaustive switch
     * 2. Apply appropriate Elixir formatting for each literal type
     * 3. Handle context-sensitive cases (TThis, TSuper)
     * 4. Return properly escaped and formatted Elixir literal
     * 
     * @param constant The TConstant to compile
     * @return Compiled Elixir literal string
     */
    public function compileConstant(constant: TConstant): String {
        #if debug_literal_compiler
        // trace("[XRay LiteralCompiler] CONSTANT COMPILATION START");
        // trace('[XRay LiteralCompiler] Constant type: ${constant}');
        #end
        
        var result = switch (constant) {
            case TInt(i): 
                #if debug_literal_compiler
                // trace('[XRay LiteralCompiler] ✓ INTEGER LITERAL: ${i}');
                #end
                Std.string(i);
                
            case TFloat(s): 
                #if debug_literal_compiler
                // trace('[XRay LiteralCompiler] ✓ FLOAT LITERAL: ${s}');
                #end
                s;
                
            case TString(s): 
                #if debug_literal_compiler
                // trace('[XRay LiteralCompiler] ✓ STRING LITERAL: ${s.substring(0, 50)}...');
                #end
                compileStringLiteral(s);
                
            case TBool(b): 
                #if debug_literal_compiler
                // trace('[XRay LiteralCompiler] ✓ BOOLEAN LITERAL: ${b}');
                #end
                b ? "true" : "false";
                
            case TNull: 
                #if debug_literal_compiler
                // trace('[XRay LiteralCompiler] ✓ NULL LITERAL');
                #end
                "nil";
                
            case TThis: 
                #if debug_literal_compiler
                // trace('[XRay LiteralCompiler] ✓ THIS REFERENCE');
                #end
                compileThisReference();
                
            case TSuper: 
                #if debug_literal_compiler
                // trace('[XRay LiteralCompiler] ✓ SUPER REFERENCE (mapped to Exception)');
                #end
                "\"Exception\""; // Elixir doesn't have super() - return base type string
                
            case _: 
                #if debug_literal_compiler
                // trace('[XRay LiteralCompiler] ⚠ UNKNOWN CONSTANT TYPE');
                #end
                "nil";
        };
        
        #if debug_literal_compiler
        // trace('[XRay LiteralCompiler] Generated literal: ${result}');
        // trace("[XRay LiteralCompiler] CONSTANT COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile string literal with proper Elixir escaping
     * 
     * WHY: String literals need comprehensive escaping for Elixir syntax compatibility
     * 
     * WHAT: Transforms Haxe string content to properly escaped Elixir string literals
     * 
     * HOW:
     * 1. Escape backslashes first (order matters for escaping)
     * 2. Escape double quotes for string delimiter compatibility
     * 3. Escape control characters (newline, carriage return, tab)
     * 4. Wrap in double quotes for Elixir string literal format
     * 
     * @param s The raw string content
     * @return Properly escaped Elixir string literal
     */
    public function compileStringLiteral(s: String): String {
        #if debug_literal_compiler
        // trace("[XRay LiteralCompiler] STRING ESCAPING START");
        // trace('[XRay LiteralCompiler] Raw string length: ${s.length}');
        #end
        
        // Properly escape string content for Elixir
        var escaped = StringTools.replace(s, '\\', '\\\\'); // Escape backslashes first
        escaped = StringTools.replace(escaped, '"', '\\"');  // Escape double quotes
        escaped = StringTools.replace(escaped, '\n', '\\n'); // Escape newlines
        escaped = StringTools.replace(escaped, '\r', '\\r'); // Escape carriage returns
        escaped = StringTools.replace(escaped, '\t', '\\t'); // Escape tabs
        
        var result = '"${escaped}"';
        
        #if debug_literal_compiler
        // trace('[XRay LiteralCompiler] Escaped string length: ${escaped.length}');
        // trace("[XRay LiteralCompiler] STRING ESCAPING END");
        #end
        
        return result;
    }
    
    /**
     * Compile "this" reference with context awareness
     * 
     * WHY: "this" references need different mapping based on context (struct methods, modules, etc.)
     * 
     * WHAT: Maps "this" to appropriate Elixir equivalent based on current compilation context
     * 
     * HOW:
     * 1. Check currentFunctionParameterMap for context-specific mapping
     * 2. Fall back to __MODULE__ for module-level context
     * 3. Handle special cases like struct methods mapping to "struct"
     * 
     * @return Appropriate Elixir equivalent for "this" reference
     */
    private function compileThisReference(): String {
        #if debug_literal_compiler
        // trace("[XRay LiteralCompiler] THIS REFERENCE COMPILATION START");
        #end
        
        // Check if 'this' should be mapped to a parameter (e.g., 'struct' in instance methods)
        var mappedName = compiler.currentFunctionParameterMap.get("this");
        var result = mappedName != null ? mappedName : "__MODULE__"; // Default to __MODULE__ if no mapping
        
        #if debug_literal_compiler
        // trace('[XRay LiteralCompiler] This mapped to: ${result}');
        // trace("[XRay LiteralCompiler] THIS REFERENCE COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Utility: Escape string content for safe inclusion in Elixir code
     * 
     * WHY: Multiple expression types need string escaping (interpolation, concatenation, etc.)
     * 
     * WHAT: Reusable string escaping function for use by other compilers
     * 
     * HOW: Same escaping logic as compileStringLiteral but without quote wrapping
     * 
     * @param s The raw string content to escape
     * @return Escaped string content (without surrounding quotes)
     */
    public function escapeStringContent(s: String): String {
        var escaped = StringTools.replace(s, '\\', '\\\\'); // Escape backslashes first
        escaped = StringTools.replace(escaped, '"', '\\"');  // Escape double quotes
        escaped = StringTools.replace(escaped, '\n', '\\n'); // Escape newlines
        escaped = StringTools.replace(escaped, '\r', '\\r'); // Escape carriage returns
        escaped = StringTools.replace(escaped, '\t', '\\t'); // Escape tabs
        return escaped;
    }
    
    /**
     * Utility: Create quoted string literal from raw content
     * 
     * WHY: Consistent string literal creation across different expression contexts
     * 
     * WHAT: Combines escaping and quote wrapping for complete string literal generation
     * 
     * HOW: Escape content and wrap in double quotes
     * 
     * @param s The raw string content
     * @return Complete Elixir string literal with quotes
     */
    public function createStringLiteral(s: String): String {
        return '"${escapeStringContent(s)}"';
    }
}

#end