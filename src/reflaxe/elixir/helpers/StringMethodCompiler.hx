package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;

using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * StringMethodCompiler: Specialized compiler for String method calls
 * 
 * WHY: String method compilation was embedded in ElixirCompiler, adding unnecessary size.
 *      String operations have specific Elixir equivalents that benefit from centralized handling.
 * 
 * WHAT: Handles all String method compilation for Haxe-to-Elixir transpilation:
 * - charAt/charCodeAt → String.at/binary operations
 * - toLowerCase/toUpperCase → String.downcase/upcase
 * - substr/substring → String.slice
 * - indexOf → :binary.match
 * - split/trim/length → String operations
 * 
 * HOW: Maps Haxe String methods to idiomatic Elixir String module functions:
 * 1. Analyzes method name and arguments
 * 2. Generates appropriate Elixir String module calls
 * 3. Handles edge cases like nil returns
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles String methods
 * - Clear Interface: Simple public API for String compilation
 * - Reduces ElixirCompiler size: Extracts ~52 lines
 * - Testability: String operations isolated from general compilation
 * - Maintainability: String patterns centralized in one place
 * 
 * EDGE CASES:
 * - charCodeAt returns nil for out of bounds
 * - indexOf returns -1 for not found
 * - substr/substring handle negative indices
 * - Empty string returns for invalid operations
 */
@:nullSafety(Off)
class StringMethodCompiler {
    
    /** Reference to main compiler for expression compilation */
    var compiler: ElixirCompiler;
    
    /**
     * Constructor
     * @param compiler Main ElixirCompiler instance for delegation
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
        
        #if debug_string_compilation
        trace("[StringMethodCompiler] Initialized");
        #end
    }
    
    /**
     * Check if a method is a String method
     * 
     * WHY: Need to identify String operations for special handling
     * WHAT: Determines if method name is a known String method
     * HOW: Checks against list of supported String methods
     * 
     * @param methodName Method name to check
     * @return True if this is a String method
     */
    public function isStringMethod(methodName: String): Bool {
        return switch(methodName) {
            case "charAt", "charCodeAt", "toLowerCase", "toUpperCase",
                 "substr", "substring", "indexOf", "split", "trim", "length":
                true;
            default:
                false;
        };
    }
    
    /**
     * Compile String method call to Elixir
     * 
     * WHY: String methods need special translation to Elixir String module
     * WHAT: Transforms Haxe String method calls to Elixir equivalents
     * HOW: Maps each method to appropriate Elixir String function
     * 
     * @param objStr Compiled String object
     * @param methodName Method being called
     * @param args Method arguments
     * @return Generated Elixir String operation
     */
    public function compileStringMethod(objStr: String, methodName: String, args: Array<TypedExpr>): String {
        #if debug_string_compilation
        trace('[StringMethodCompiler] Compiling String method: ${methodName}');
        #end
        
        var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
        
        return switch (methodName) {
            case "charCodeAt":
                // s.charCodeAt(pos) → String.to_charlist(s) |> Enum.at(pos) 
                if (compiledArgs.length > 0) {
                    'case String.at(${objStr}, ${compiledArgs[0]}) do nil -> nil; c -> :binary.first(c) end';
                } else {
                    'nil';
                }
                
            case "charAt":
                // s.charAt(pos) → String.at(s, pos)
                if (compiledArgs.length > 0) {
                    'String.at(${objStr}, ${compiledArgs[0]})';
                } else {
                    '""';
                }
                
            case "toLowerCase":
                'String.downcase(${objStr})';
                
            case "toUpperCase":
                'String.upcase(${objStr})';
                
            case "substr", "substring":
                // Handle substr/substring with Elixir's String.slice
                if (compiledArgs.length >= 2) {
                    'String.slice(${objStr}, ${compiledArgs[0]}, ${compiledArgs[1]})';
                } else if (compiledArgs.length == 1) {
                    'String.slice(${objStr}, ${compiledArgs[0]}..-1)';
                } else {
                    objStr;
                }
                
            case "indexOf":
                // s.indexOf(substr) → find index or -1
                if (compiledArgs.length > 0) {
                    'case :binary.match(${objStr}, ${compiledArgs[0]}) do {pos, _} -> pos; :nomatch -> -1 end';
                } else {
                    '-1';
                }
                
            case "split":
                if (compiledArgs.length > 0) {
                    'String.split(${objStr}, ${compiledArgs[0]})';
                } else {
                    '[${objStr}]';
                }
                
            case "trim":
                'String.trim(${objStr})';
                
            case "length":
                'String.length(${objStr})';
                
            default:
                // Default: try to call as a regular method (might fail at runtime)
                '${objStr}.${methodName}(${compiledArgs.join(", ")})';
        };
    }
}

#end