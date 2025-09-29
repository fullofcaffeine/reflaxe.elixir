package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.CompilationContext;

/**
 * VariableBuilder: Handles variable and local reference building
 * 
 * WHY: Separates complex variable resolution logic from ElixirASTBuilder
 * - Reduces ElixirASTBuilder complexity significantly
 * - Centralizes variable name resolution and mapping
 * - Handles special infrastructure variables (g_, rec_, etc.)
 * 
 * WHAT: Builds ElixirAST nodes for variable references
 * - TVar expressions (23+ different cases)
 * - TLocal expressions
 * - Infrastructure variable detection
 * - Pattern extraction variable handling
 * - Loop and clause context variable resolution
 * 
 * HOW: Complex priority-based variable resolution
 * - Checks pattern registry for enum extraction vars
 * - Checks clause context for case-local variables
 * - Checks global variable mappings
 * - Handles special infrastructure patterns
 */
@:nullSafety(Off)
class VariableBuilder {
    
    /**
     * Build variable reference expressions
     * 
     * @param tvar The variable to reference
     * @param expr The full typed expression (for metadata)
     * @param context Build context with compilation state
     * @return ElixirASTDef for the variable reference
     */
    public static function buildVar(tvar: TVar, expr: TypedExpr, context: CompilationContext): ElixirASTDef {
        var variableName = resolveVariableName(tvar, context);
        
        #if debug_ast_builder
        trace('[AST Builder] TVar: ${tvar.name} (id: ${tvar.id}) -> $variableName');
        #end
        
        return EVar(variableName);
    }
    
    /**
     * Build local variable reference expressions
     * 
     * @param tvar The local variable to reference
     * @param expr The full typed expression
     * @param context Build context with compilation state
     * @return ElixirASTDef for the local reference
     */
    public static function buildLocal(tvar: TVar, expr: TypedExpr, context: CompilationContext): ElixirASTDef {
        // TLocal is similar to TVar but represents a local variable in the current scope
        var variableName = resolveVariableName(tvar, context);
        
        #if debug_ast_builder
        trace('[AST Builder] TLocal: ${tvar.name} (id: ${tvar.id}) -> $variableName');
        #end
        
        return EVar(variableName);
    }
    
    /**
     * Resolve the actual variable name to use in generated code
     * 
     * WHY: Variables can be renamed/mapped during compilation
     * WHAT: Priority-based resolution system
     * HOW: 
     * 1. Check pattern registry (highest priority - enum extraction)
     * 2. Check clause context (case-local variables)
     * 3. Check global mappings (function params, etc.)
     * 4. Check infrastructure patterns (g_, rec_, etc.)
     * 5. Use default name
     */
    static function resolveVariableName(tvar: TVar, context: CompilationContext): String {
        var tvarId = tvar.id;
        var defaultName = tvar.name;
        
        // Priority 1: Check pattern registry for enum pattern extraction
        if (context.patternVariableRegistry != null && context.patternVariableRegistry.exists(tvarId)) {
            var patternName = context.patternVariableRegistry.get(tvarId);
            #if debug_pattern_variables
            trace('[Pattern Variable] Using pattern registry mapping: ${tvar.name} (id: $tvarId) -> $patternName');
            #end
            return patternName;
        }
        
        // Priority 2: Check clause context for case-local variables
        if (context.currentClauseContext != null) {
            var clauseMapping = context.currentClauseContext.getVariableMapping(tvarId);
            if (clauseMapping != null) {
                #if debug_clause_context
                trace('[Clause Context] Found mapping for ${tvar.name} (id: $tvarId) -> $clauseMapping');
                #end
                return clauseMapping;
            }
        }
        
        // Priority 3: Check global variable mappings
        if (context.variableMappings != null && context.variableMappings.exists(tvarId)) {
            var mapping = context.variableMappings.get(tvarId);
            #if debug_variable_mappings
            trace('[Variable Mapping] Found global mapping: ${tvar.name} (id: $tvarId) -> $mapping');
            #end
            return mapping;
        }
        
        // Priority 4: Check for infrastructure variables
        if (isInfrastructureVariable(defaultName)) {
            var infraName = handleInfrastructureVariable(tvar, context);
            if (infraName != null) {
                return infraName;
            }
        }
        
        // Priority 5: Check loop preservation
        if (context.preservedLoopVariables != null && context.preservedLoopVariables.exists(tvarId)) {
            var preserved = context.preservedLoopVariables.get(tvarId);
            #if debug_loop_variables
            trace('[Loop Variable] Using preserved name: ${tvar.name} (id: $tvarId) -> $preserved');
            #end
            return preserved;
        }
        
        // Default: Use the variable's original name
        return defaultName;
    }
    
    /**
     * Check if a variable is an infrastructure variable
     * 
     * WHY: Infrastructure variables need special handling
     * WHAT: Variables starting with g_, rec_, etc.
     * HOW: Pattern matching on variable name prefix
     */
    static function isInfrastructureVariable(name: String): Bool {
        return name.startsWith("g_") || 
               name.startsWith("rec_") || 
               name.startsWith("__") ||
               name == "this" ||
               name == "self";
    }
    
    /**
     * Handle special infrastructure variables
     * 
     * WHY: These variables have special meaning in compilation
     * WHAT: g_ (generated), rec_ (recursive), __ (internal)
     * HOW: Context-aware name resolution
     */
    static function handleInfrastructureVariable(tvar: TVar, context: CompilationContext): Null<String> {
        var name = tvar.name;
        
        // Handle g_ variables (generated temporaries)
        if (name.startsWith("g_")) {
            // Check if this g_ variable has a specific mapping
            if (context.generatedVariableMappings != null && 
                context.generatedVariableMappings.exists(tvar.id)) {
                return context.generatedVariableMappings.get(tvar.id);
            }
            
            // For switch expressions, g_ variables often need special handling
            if (context.isInSwitchExpression) {
                // The g_ variable might be the switch expression result variable
                return name; // Keep as-is for now
            }
        }
        
        // Handle rec_ variables (recursive function helpers)
        if (name.startsWith("rec_")) {
            // These are usually generated for recursive anonymous functions
            // Keep the name but might need transformation
            return name;
        }
        
        // Handle __ variables (compiler internals)
        if (name.startsWith("__")) {
            // These should generally be preserved as-is
            return name;
        }
        
        // Handle 'this' reference
        if (name == "this" || name == "self") {
            // Use context to determine the actual receiver name
            if (context.currentReceiverParamName != null) {
                return context.currentReceiverParamName;
            }
            // In ExUnit tests, 'this' refers to context
            if (context.isInExUnitTest) {
                return "context";
            }
            // Default fallback
            return "__instance_variable_not_available_in_this_context__";
        }
        
        return null;
    }
    
    /**
     * Register a pattern extraction variable
     * 
     * WHY: Enum pattern matching extracts variables that need tracking
     * WHAT: Maps TVar ID to the extracted pattern name
     * HOW: Updates the pattern registry in context
     * 
     * @param tvarId The variable ID
     * @param patternName The extracted pattern variable name
     * @param context The compilation context
     */
    public static function registerPatternVariable(tvarId: Int, patternName: String, context: CompilationContext): Void {
        if (context.patternVariableRegistry == null) {
            context.patternVariableRegistry = new Map<Int, String>();
        }
        
        context.patternVariableRegistry.set(tvarId, patternName);
        
        #if debug_pattern_variables
        trace('[Pattern Variable] Registered: var $tvarId -> $patternName');
        #end
    }
    
    /**
     * Register a global variable mapping
     * 
     * WHY: Variables can be renamed during compilation
     * WHAT: Maps TVar ID to the new name
     * HOW: Updates the global variable mappings
     * 
     * @param tvarId The variable ID
     * @param newName The new variable name
     * @param context The compilation context
     */
    public static function registerGlobalVariable(tvarId: Int, newName: String, context: CompilationContext): Void {
        if (context.variableMappings == null) {
            context.variableMappings = new Map<Int, String>();
        }
        
        context.variableMappings.set(tvarId, newName);
        
        #if debug_variable_mappings
        trace('[Variable Mapping] Registered global: var $tvarId -> $newName');
        #end
    }
    
    /**
     * Clear pattern variable registry
     * 
     * WHY: Pattern variables are scoped to their match expression
     * WHAT: Clears the pattern registry
     * HOW: Resets the registry map
     * 
     * @param context The compilation context
     */
    public static function clearPatternVariables(context: CompilationContext): Void {
        context.patternVariableRegistry = null;
        
        #if debug_pattern_variables
        trace('[Pattern Variable] Registry cleared');
        #end
    }
    
    /**
     * Preserve loop variable name
     * 
     * WHY: Loop variables need consistent naming across iterations
     * WHAT: Preserves the variable name for loop body
     * HOW: Adds to preserved loop variables map
     * 
     * @param tvarId The variable ID
     * @param name The name to preserve
     * @param context The compilation context
     */
    public static function preserveLoopVariable(tvarId: Int, name: String, context: CompilationContext): Void {
        if (context.preservedLoopVariables == null) {
            context.preservedLoopVariables = new Map<Int, String>();
        }
        
        context.preservedLoopVariables.set(tvarId, name);
        
        #if debug_loop_variables
        trace('[Loop Variable] Preserved: var $tvarId -> $name');
        #end
    }
}

#end