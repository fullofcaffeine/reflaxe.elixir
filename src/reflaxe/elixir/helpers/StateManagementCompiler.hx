#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;

/**
 * StateManagementCompiler: Centralized state threading and parameter mapping management
 * 
 * WHY: Haxe's mutable object model needs transformation to Elixir's immutable structs.
 *      State threading allows mutating operations to thread updated state through function calls.
 *      Parameter mapping ensures 'this' references resolve correctly in struct methods.
 * WHAT: Manages state threading flags, parameter mappings, and coordinate transformations
 *       between Haxe's mutable semantics and Elixir's immutable struct updates.
 * HOW: Provides centralized parameter mapping, state threading control, and context management
 *      for methods that need to transform field assignments into struct updates.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused entirely on state and parameter management
 * - Open/Closed Principle: Easy to extend with new mapping strategies
 * - Testability: State management logic can be tested independently
 * - Maintainability: Clear separation from expression compilation logic
 * - Performance: Optimized parameter lookup and state tracking
 * 
 * EDGE CASES:
 * - Nested function calls with multiple parameter contexts
 * - Global vs local parameter mapping conflicts
 * - State threading in inline functions and lambdas
 * - Complex struct method inheritance patterns
 * 
 * @see docs/03-compiler-development/STATE_MANAGEMENT.md - Complete state threading guide
 */
@:nullSafety(Off)
class StateManagementCompiler {
    var compiler: ElixirCompiler;

    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }

    /**
     * Enable state threading mode for mutating methods
     * 
     * WHY: Transform field assignments to struct updates with proper state flow
     * WHAT: Activates transformation of field assignments to struct updates
     * HOW: Sets flags that OperatorCompiler and other helpers check
     * 
     * @param info Mutability analysis results from MutabilityAnalyzer
     */
    public function enableStateThreadingMode(info: reflaxe.elixir.helpers.MutabilityAnalyzer.MutabilityInfo): Void {
        compiler.stateThreadingEnabled = true;
        compiler.stateThreadingInfo = info;
        
        #if debug_state_threading
//         trace('[StateManagementCompiler] State threading enabled for mutating method');
        #end
    }

    /**
     * Disable state threading mode
     * 
     * WHY: State threading should only apply to specific mutating methods
     * WHAT: Resets transformation flags to normal compilation mode
     * HOW: Clears flags and mutability info
     */
    public function disableStateThreadingMode(): Void {
        compiler.stateThreadingEnabled = false;
        compiler.stateThreadingInfo = null;
        
        #if debug_state_threading
//         trace('[StateManagementCompiler] State threading disabled');
        #end
    }

    /**
     * Check if state threading is currently enabled
     * 
     * WHY: Other helpers need to know if state transformations should be applied
     * WHAT: Returns current state threading status
     * HOW: Simple flag check
     * 
     * @return True if state threading transformations should be applied
     */
    public function isStateThreadingEnabled(): Bool {
        return compiler.stateThreadingEnabled;
    }

    /**
     * Get current mutability information
     * 
     * WHY: State threading helpers need access to analysis results
     * WHAT: Returns analysis results from MutabilityAnalyzer
     * HOW: Returns stored mutability info
     * 
     * @return Mutability analysis results or null
     */
    public function getStateThreadingInfo(): Null<reflaxe.elixir.helpers.MutabilityAnalyzer.MutabilityInfo> {
        return compiler.stateThreadingInfo;
    }

    /**
     * Set parameter mapping for 'this' references
     * 
     * WHY: Struct methods need 'this' to map to the struct parameter name
     * WHAT: Creates mapping from 'this'/_this/struct to actual parameter name
     * HOW: Updates the current function parameter map
     * 
     * @param structParamName The actual parameter name for the struct
     */
    public function setParameterMapping(structParamName: String): Void {
        compiler.currentFunctionParameterMap.set("this", structParamName);
        // Map _this which Haxe generates during desugaring
        compiler.currentFunctionParameterMap.set("_this", structParamName);
        // Also map struct for consistency
        compiler.currentFunctionParameterMap.set("struct", structParamName);
        
        #if (debug_parameter_mapping || debug_variable_compiler)
//         trace('[StateManagementCompiler] Set this parameter mapping to: ${structParamName}');
//         trace('[StateManagementCompiler] Parameter map now contains: ${[for (k in compiler.currentFunctionParameterMap.keys()) '${k}->${compiler.currentFunctionParameterMap.get(k)}'].join(", ")}');
        #end
    }

    /**
     * Clear parameter mapping after method compilation
     * 
     * WHY: Parameter mappings should be function-scoped
     * WHAT: Removes 'this' mappings from the parameter map
     * HOW: Clears specific keys from the map
     */
    public function clearParameterMapping(): Void {
        compiler.currentFunctionParameterMap.remove("this");
        compiler.currentFunctionParameterMap.remove("_this");
        compiler.currentFunctionParameterMap.remove("struct");
        
        #if debug_parameter_mapping
//         trace('[StateManagementCompiler] Cleared this parameter mapping');
        #end
    }

    /**
     * Start compiling a struct method globally
     * 
     * WHY: JsonPrinter _this issue - ensure _this mapping persists through ALL nested contexts
     * WHAT: Creates global parameter mapping that survives context switches
     * HOW: Sets global mapping and enables global struct compilation flag
     * 
     * @param structParamName The parameter name to map _this to globally
     */
    public function startGlobalStructMethodCompilation(structParamName: String): Void {
        compiler.isCompilingStructMethod = true;
        compiler.globalStructParameterMap.set("_this", structParamName);
        compiler.globalStructParameterMap.set("this", structParamName);
        compiler.globalStructParameterMap.set("struct", structParamName);
        
        #if debug_state_threading
//         trace('[StateManagementCompiler] 🌍 GLOBAL struct method compilation started');
//         trace('[StateManagementCompiler] 🌍 Global mapping: _this -> ${structParamName}');
        #end
    }

    /**
     * Stop compiling struct method globally
     * 
     * WHY: Global mappings should be method-scoped
     * WHAT: Clears global mappings and disables global struct compilation
     * HOW: Resets global mapping and flag
     */
    public function stopGlobalStructMethodCompilation(): Void {
        compiler.isCompilingStructMethod = false;
        compiler.globalStructParameterMap.clear();
        
        #if debug_state_threading
//         trace('[StateManagementCompiler] 🌍 GLOBAL struct method compilation stopped');
        #end
    }

    /**
     * Set inline context for variable replacement
     * 
     * WHY: Some variables need to be replaced during compilation
     * WHAT: Maps variable names to their replacement values
     * HOW: Updates the inline context map
     * 
     * @param variableName The variable to replace
     * @param replacementValue The value to replace it with
     */
    public function setInlineContext(variableName: String, replacementValue: String): Void {
        compiler.inlineContextMap.set(variableName, replacementValue);
        
        #if debug_inline_context
//         trace('[StateManagementCompiler] Set inline context: ${variableName} -> ${replacementValue}');
        #end
    }

    /**
     * Clear inline context
     * 
     * WHY: Inline context should be function-scoped
     * WHAT: Clears all inline variable mappings
     * HOW: Resets the inline context map
     */
    public function clearInlineContext(): Void {
        compiler.inlineContextMap.clear();
        
        #if debug_inline_context
//         trace('[StateManagementCompiler] Cleared inline context');
        #end
    }

    /**
     * Check if inline context exists for a variable
     * 
     * WHY: Need to determine if a variable has an inline replacement
     * WHAT: Checks if the variable exists in the inline context map
     * HOW: Returns true if the variable has been mapped
     * 
     * @param varName The variable name to check
     * @return True if the variable has an inline context mapping
     */
    public function hasInlineContext(varName: String): Bool {
        return compiler.inlineContextMap.exists(varName);
    }

    /**
     * Get inline context value for a variable
     * 
     * WHY: Need to retrieve replacement values for inline context
     * WHAT: Gets the replacement value for a variable
     * HOW: Returns the mapped value or null if not found
     * 
     * @param varName The variable name to check
     * @return The replacement value or null if not mapped
     */
    public function getInlineContext(varName: String): Null<String> {
        return compiler.inlineContextMap.get(varName);
    }

    /**
     * Get the effective variable name for 'this' references, considering inline context
     * 
     * WHY: 'this' references need context-aware resolution in different scopes
     * WHAT: Resolves 'this' to the appropriate parameter name or default
     * HOW: Checks inline context first, then parameter mapping, then defaults
     * 
     * @return The effective variable name for 'this' references
     */
    public function resolveThisReference(): String {
        // Check inline context first (highest priority)
        var inlineThis = compiler.inlineContextMap.get("this");
        if (inlineThis != null) {
            return inlineThis;
        }
        
        // Check parameter mapping
        var mapped = compiler.currentFunctionParameterMap.get("this");
        var result = mapped != null ? mapped : "struct";
        return result;
    }
}

#end