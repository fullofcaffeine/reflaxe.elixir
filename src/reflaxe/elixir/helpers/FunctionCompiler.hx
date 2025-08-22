package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.TypedExpr;
import reflaxe.data.ClassFuncData;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.DebugHelper;

using StringTools;

/**
 * FunctionCompiler: Specialized compilation of class functions to idiomatic Elixir
 * 
 * WHY: Function compilation involves complex logic including parameter mapping,
 * pipeline optimization, LiveView callback handling, and proper Elixir function
 * formatting. This was extracted from ElixirCompiler.hx to follow single 
 * responsibility principle and reduce main compiler complexity.
 * 
 * WHAT: Transforms Haxe class functions into idiomatic Elixir function definitions:
 * - Parameter name conversion (camelCase → snake_case)
 * - LiveView callback parameter override support
 * - Pipeline optimization for function body compilation
 * - Proper function documentation generation
 * - Body indentation and formatting for Elixir conventions
 * - Fallback handling for empty or null function bodies
 * 
 * HOW: 
 * 1. Extract function metadata (name, parameters, body)
 * 2. Apply parameter naming conversions with LiveView overrides
 * 3. Analyze function body for pipeline optimization opportunities
 * 4. Compile function body with proper context (topLevel = true)
 * 5. Format result with Elixir function definition syntax
 * 6. Handle edge cases (empty bodies, compilation failures)
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused only on function compilation logic
 * - Open/Closed Principle: Extensible for new function patterns
 * - Testability: Can be unit tested independently from main compiler
 * - Maintainability: Clear separation from class and expression compilation
 * - Performance: Specialized optimizations for function-specific patterns
 * 
 * EDGE CASES:
 * - LiveView callbacks require specific parameter naming
 * - Empty or null function bodies need proper nil fallback
 * - Pipeline optimization may not apply to all function bodies
 * - Compilation failures need graceful degradation
 * 
 * @see documentation/FUNCTION_COMPILATION.md - Detailed function compilation patterns
 */
@:nullSafety(Off)
class FunctionCompiler {
    
    private var compiler: reflaxe.elixir.ElixirCompiler;
    
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * FUNCTION COMPILATION: Transform Haxe class function to idiomatic Elixir function
     * 
     * WHY: Haxe functions need careful translation to Elixir to preserve semantics
     * while following Elixir conventions. Parameter names, documentation, and body
     * formatting all require specialized handling for different function types.
     * 
     * WHAT: Generates complete Elixir function definition with:
     * - @doc documentation from Haxe function name
     * - def function_name(parameters) do ... end structure
     * - Proper parameter name conversion (camelCase → snake_case)
     * - LiveView callback parameter override when applicable
     * - Pipeline-optimized function body compilation
     * - Appropriate indentation and formatting
     * 
     * HOW:
     * 1. Convert function name to snake_case using NamingHelper
     * 2. Check for LiveView callback parameter overrides
     * 3. Build parameter list with proper naming conversion
     * 4. Generate function documentation and signature
     * 5. Compile function body with pipeline optimization detection
     * 6. Apply proper indentation and formatting
     * 7. Handle edge cases (empty bodies, compilation failures)
     * 
     * LIVEVIEW INTEGRATION: LiveView callbacks like mount/3, handle_event/3
     * require specific parameter names (params, session, socket) rather than
     * generic camelCase conversions. This function checks for these patterns.
     * 
     * PIPELINE OPTIMIZATION: Multi-statement function bodies are analyzed for
     * pipeline patterns that can be compiled to idiomatic Elixir |> chains.
     * 
     * @param funcField The Haxe function data including name, parameters, and body
     * @param isStatic Whether this is a static function (currently unused)
     * @return Complete Elixir function definition string
     */
    public function compileFunction(funcField: ClassFuncData, isStatic: Bool = false): String {
        var funcName = NamingHelper.getElixirFunctionName(funcField.field.name);
        
        #if debug_function_compilation
        DebugHelper.debugFunction("compileFunction", "Starting compilation", 'Function: ${funcName}, Static: ${isStatic}');
        #end
        
        // Build parameter list - check for LiveView callback override first
        var paramStr = "";
        var liveViewParams = reflaxe.elixir.LiveViewCompiler.getLiveViewCallbackParams(funcName);
        
        if (liveViewParams != null) {
            // Use LiveView-specific parameter names for callbacks
            paramStr = liveViewParams;
            #if debug_function_compilation
            DebugHelper.debugFunction("LiveView Override", "Using LiveView parameters", 'Params: ${paramStr}');
            #end
        } else {
            // Use actual parameter names converted to snake_case for regular functions
            var params = [];
            for (i in 0...funcField.args.length) {
                var arg = funcField.args[i];
                // Get the actual parameter name from tvar (consistent with setFunctionParameterMapping)
                var originalName = if (arg.tvar != null) {
                    arg.tvar.name;
                } else {
                    // Fallback to getName() if tvar is not available
                    arg.getName();
                }
                var paramName = NamingHelper.toSnakeCase(originalName);
                params.push(paramName);
            }
            paramStr = params.join(", ");
            #if debug_function_compilation
            DebugHelper.debugFunction("Parameter Conversion", "Converted parameters", 'Params: ${paramStr}');
            #end
        }
        
        // Generate function documentation and signature
        var result = '  @doc "Generated from Haxe ${funcField.field.name}"\n';
        result += '  def ${funcName}(${paramStr}) do\n';
        
        if (funcField.expr != null) {
            // Compile function body with topLevel = true for function bodies
            // Pipeline optimization is temporarily disabled, so use regular compilation
            var compiledBody = compiler.compileExpressionImpl(funcField.expr, true);
            
            #if debug_function_compilation
            DebugHelper.debugFunction("Body Compilation", "Regular compilation used", 'Expression type: ${funcField.expr.expr}');
            #end
            
            if (compiledBody != null && compiledBody.trim() != "") {
                // Indent the function body properly
                var indentedBody = compiledBody.split("\n").map(line -> line.length > 0 ? "    " + line : line).join("\n");
                result += '${indentedBody}\n';
                #if debug_function_compilation
                DebugHelper.debugFunction("Body Compilation", "✓ SUCCESS", 'Body length: ${compiledBody.length} chars');
                #end
            } else {
                // Only use nil if compilation actually failed/returned empty
                result += '    nil\n';
                #if debug_function_compilation
                DebugHelper.debugFunction("Body Compilation", "⚠ FALLBACK to nil", 'Compiled body was empty or null');
                #end
            }
        } else {
            // No expression provided - this is a truly empty function
            result += '    nil\n';
            #if debug_function_compilation
            DebugHelper.debugFunction("Function Body", "No expression provided", 'Using nil fallback');
            #end
        }
        result += '  end\n\n';
        
        #if debug_function_compilation
        DebugHelper.debugFunction("compileFunction", "✓ COMPLETION", 'Generated ${result.split("\n").length} lines');
        #end
        
        return result;
    }
}

#end