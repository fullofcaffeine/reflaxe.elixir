package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;import haxe.macro.Expr;
import reflaxe.elixir.ElixirCompiler;import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * Variable Compiler for Reflaxe.Elixir with TVar.id-based Variable Identity Tracking
 * 
 * WHY: Variable name collisions in generated Elixir code revealed fundamental issues with
 * string-based variable mapping. The compiler was generating code like `((g_array < g_array))`
 * where both counter and limit variables had identical names, causing runtime errors. This happened
 * because multiple TVar instances with the same `.name` but different `.id` values were being
 * mapped to the same string key, causing collisions. The solution is to use TVar.id as the unique
 * identifier for variable mapping, following the pattern established by Reflaxe's MarkUnusedVariablesImpl.
 * 
 * WHAT: TVar.id-based variable identity system for collision-free variable compilation:
 * - Unique Variable Identity: Uses TVar.id (integer) as Map key instead of variable name (string)
 * - Collision Prevention: Multiple variables with same name but different IDs map to different outputs
 * - Reflaxe Integration: Follows established patterns from MarkUnusedVariablesImpl preprocessor
 * - Metadata Support: Checks for `-reflaxe.unused` metadata to skip unused variable generation
 * - Context-Aware Mapping: Maintains all existing functionality with proper unique identification
 * - Framework Integration: Preserves LiveView, function reference, and struct update patterns
 * 
 * HOW: TVar.id-based mapping system with deterministic variable resolution:
 * 1. Creates Map<Int, String> using TVar.id as unique key (not variable name)
 * 2. Maps each TVar.id to its appropriate transformed name (snake_case, context-specific)
 * 3. Resolves variable references by looking up TVar.id in the mapping table
 * 4. Falls back to standard name transformation if no specific mapping exists
 * 5. Maintains all existing context logic (LiveView, struct updates, function references)
 * 
 * ARCHITECTURE BENEFITS:
 * - Collision-Free Mapping: Impossible for different variables to map to same name
 * - Reflaxe Alignment: Uses same patterns as established preprocessors
 * - Deterministic Output: Same TVar.id always produces same variable name
 * - Performance Optimized: Integer keys faster than string keys in Map operations
 * - Framework Compatible: All existing patterns continue to work correctly
 * - Future-Proof: Handles any variable collision scenario automatically
 * 
 * FIXED ISSUES:
 * - Variable name collisions in desugared for-loops (g_array < g_array)
 * - Orphaned enum parameter variable references
 * - Inconsistent variable mapping between TLocal and TVar compilation
 * - Heuristic detection failures in complex variable scenarios
 * 
 * @see docs/03-compiler-development/VARIABLE_MAPPING_FIX.md - Complete solution documentation
 */
@:nullSafety(Off)
class VariableCompiler {
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    
    /**
     * TVar.id-based variable mapping for collision-free variable resolution
     * 
     * WHY: String-based mapping caused collisions when multiple variables had same name but different TVar.id
     * WHAT: Maps unique TVar.id (Int) to transformed variable name (String)
     * HOW: Uses TVar.id as key, eliminating possibility of name collisions
     */
    public var variableIdMap: Map<Int, String> = new Map();
    
    /**
     * Map of variable names to their underscore-prefixed versions
     * Critical for tracking unused variables across declaration and reference
     */
    public var underscorePrefixMap: Map<String, String> = new Map();
    
    /**
     * Position tracking for TVar instances (for error reporting)
     * Following the pattern from MarkUnusedVariablesImpl
     */
    var tvarPos: Map<Int, haxe.macro.Expr.Position> = new Map();
    
    /**
     * Create a new variable compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Compile TLocal local variable expressions
     * 
     * WHY: Local variables need context-aware compilation for proper Elixir integration
     * 
     * WHAT: Transform Haxe local variable references to appropriate Elixir equivalents
     * 
     * HOW:
     * 1. Get original variable name (before Haxe's renaming)
     * 2. Apply context-specific mappings (struct, LiveView, function references)
     * 3. Handle parameter mapping for consistent naming
     * 4. Generate appropriate Elixir variable reference
     * 
     * @param v The TVar representing the local variable
     * @return Compiled Elixir variable reference
     */
    /**
     * Register a variable mapping using TVar.id as unique identifier
     * 
     * WHY: Prevents variable name collisions by using unique TVar.id as key
     * WHAT: Maps TVar.id to transformed variable name
     * HOW: Stores mapping in variableIdMap for later resolution
     */
    public function registerVariableMapping(tvar: TVar, mappedName: String): Void {
        variableIdMap.set(tvar.id, mappedName);
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] ✓ REGISTERED MAPPING: TVar.id=${tvar.id} (${tvar.name}) -> ${mappedName}');
        #end
    }
    
    public function compileLocalVariable(v: TVar): String {
        #if debug_variable_compiler
        // trace("[XRay VariableCompiler] LOCAL VARIABLE COMPILATION START");
        // trace('[XRay VariableCompiler] TVar.name: ${v.name}, TVar.id: ${v.id}');
        #end
        
        // CRITICAL FIX: Don't skip unused variables - they need underscore-prefixed names!
        // The old logic returned empty string for unused variables, causing invalid Elixir code
        // where variables are declared with underscore (_params) but referenced without (params)
        
        // PRIMARY: Check TVar.id-based mapping FIRST - this takes absolute priority
        // This prevents variable collisions by using unique TVar.id as the identifier
        // This also handles underscore-prefixed names for unused variables
        var idMapping = variableIdMap.get(v.id);
        if (idMapping != null) {
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] ✓ FOUND TVAR.ID MAPPING: ${v.id} -> ${idMapping}');
            // trace('[XRay VariableCompiler] Using TVar.id mapping (may include underscore prefix)');
            #end
            return idMapping; // Return immediately - this includes underscore prefix if variable is unused
        }
        
        // Get the original variable name (before Haxe's renaming for shadowing avoidance)
        var originalName = getOriginalVarName(v);
        var snakeName = NamingHelper.toSnakeCase(originalName);
        
        #if debug_variable_compiler
        if (originalName == "params" || snakeName == "params") {
            // trace('[XRay VariableCompiler] SPECIAL DEBUG: Checking params variable');
            // trace('[XRay VariableCompiler] Original name: ${originalName}, Snake name: ${snakeName}');
            // trace('[XRay VariableCompiler] underscorePrefixMap keys: ${[for (k in underscorePrefixMap.keys()) k].join(", ")}');
        }
        #end
        
        // CHECK: Look for underscore prefix mapping by name
        // This handles cases where TVar IDs differ between declaration and reference
        var prefixedName = underscorePrefixMap.get(snakeName);
        if (prefixedName != null) {
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] ✓ FOUND UNDERSCORE PREFIX MAPPING BY NAME: ${snakeName} -> ${prefixedName}');
            #end
            return prefixedName;
        }
        
        // FALLBACK: If no mapping found, check if variable is unused and add underscore
        // This shouldn't normally happen since we track all variables
        if (v.meta != null && v.meta.has("-reflaxe.unused")) {
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] ⚠️ VARIABLE MARKED AS UNUSED BUT NO MAPPING FOUND');
            // trace('[XRay VariableCompiler] Falling back to underscore-prefixed name');
            #end
            // Add underscore prefix for unused variables
            if (!StringTools.startsWith(snakeName, "_")) {
                snakeName = "_" + snakeName;
            }
            return snakeName;
        }
        
        // NOTE: The old counting logic for 'g' variables has been removed
        // It's replaced by proper TVar.id-based mapping which is checked above
        // If we reach here and it's a 'g' variable without a mapping, 
        // it should be treated as a normal variable
        
        // CRITICAL FIX: Handle tempArray variables that were skipped in declaration
        // These variables were declared with null but skipped to prevent undefined references
        // When they're accessed, we need to generate the inline ternary instead
        var isTempArrayAccess = (
            StringTools.startsWith(originalName, "tempArray") ||
            StringTools.startsWith(originalName, "temp_array") ||
            (StringTools.startsWith(originalName, "temp") && (StringTools.contains(originalName, "Array") || StringTools.contains(originalName, "array")))
        );
        
        if (isTempArrayAccess) {
            #if debug_variable_compiler
            // trace("[XRay VariableCompiler] ⚠️ TEMP ARRAY LOCAL VARIABLE ACCESS: " + originalName);
            // trace("[XRay VariableCompiler] Checking if this should be replaced with inline expression");
            #end
            
            // Try to find a consumed temp variable mapping 
            if (compiler.consumedTempVariables != null && compiler.consumedTempVariables.exists(originalName)) {
                var inlineExpression = compiler.consumedTempVariables.get(originalName);
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ✓ FOUND CONSUMED TEMP VARIABLE MAPPING: ${originalName} -> ${inlineExpression}');
                #end
                return inlineExpression;
            }
            
            // NO FALLBACK - if no mapping exists, the variable should be generated normally
            // The ControlFlowCompiler should have captured all ternary patterns and stored mappings
            #if debug_variable_compiler
            // trace("[XRay VariableCompiler] No mapping found for temp array variable: " + originalName);
            // trace("[XRay VariableCompiler] Allowing normal variable generation");
            #end
        }
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] Original name: ${originalName}');
        #end
        
        /**
         * PARAMETER MAPPING CHECK
         * 
         * WHY: Variables like '_this' need to be mapped to their actual parameter names
         * WHAT: Check if there's a parameter mapping for this variable
         * HOW: Look up in currentFunctionParameterMap first, then inline context
         */
        // Check parameter mapping first (for function parameters)
        // trace('[XRay VariableCompiler] Checking parameter mapping for: ${originalName}');
        // trace('[XRay VariableCompiler] Parameter map has: ${[for (k in compiler.currentFunctionParameterMap.keys()) k].join(", ")}');
        
        // NOTE: Orphaned TLocal(_g) expressions are now handled at the TBlock level
        // in ControlFlowCompiler.compileBlock() using the Go compiler approach.
        // This is more reliable than context tracking and follows proven Reflaxe patterns.
        
        // Special debug for camelCase variables
        if (originalName == "bulkAction" || originalName == "alertLevel") {
            // trace('[XRay VariableCompiler] ⚠️ Looking for camelCase variable ${originalName} in parameter map');
            for (key in compiler.currentFunctionParameterMap.keys()) {
                // trace('[XRay VariableCompiler]   Map contains: ${key} -> ${compiler.currentFunctionParameterMap.get(key)}');
            }
        }
        
        // DEBUG: Check what's in the parameter map for underscore parameters
        if (originalName == "spec" || originalName == "_spec") {
            // trace('[XRay VariableCompiler] DEBUG: Looking for spec parameter mapping');
            // trace('[XRay VariableCompiler] Original name: ${originalName}');
            // trace('[XRay VariableCompiler] Parameter map keys: ${[for (k in compiler.currentFunctionParameterMap.keys()) k].join(", ")}');
            for (key in compiler.currentFunctionParameterMap.keys()) {
                // trace('[XRay VariableCompiler]   ${key} -> ${compiler.currentFunctionParameterMap.get(key)}');
            }
        }
        
        var mappedName = compiler.currentFunctionParameterMap.get(originalName);
        if (mappedName != null) {
            // trace('[XRay VariableCompiler] ✓ PARAMETER MAPPING: ${originalName} -> ${mappedName}');
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] Found in parameter map');
            #end
            
            // CRITICAL FIX: Always apply _g -> g_array mappings - they are needed for array desugaring
            // The _g variables from array desugaring should be mapped to g_array regardless of context
            if (originalName.charAt(0) == '_' && ~/^_g\d*$/.match(originalName)) {
                // trace('[XRay VariableCompiler] ✓ APPLYING array desugaring mapping for ${originalName} -> ${mappedName}');
                // This is crucial for fixing undefined _g variable errors
                return mappedName;
            }
            
            // CRITICAL FIX: Don't map 'g' to 'g_counter' in any context - it's always wrong
            // The 'g' variable is used for enum parameter extraction, never for loop counters
            if (originalName == "g" && StringTools.endsWith(mappedName, "_counter")) {
                // This mapping is ALWAYS incorrect - 'g' is for enum extraction, not loops
                // trace('[XRay VariableCompiler] ⚠️ BLOCKING incorrect g -> ${mappedName} mapping in TLocal');
                // trace('[XRay VariableCompiler] Returning "g" directly instead of ${mappedName}');
                // Don't use the incorrect mapping - return 'g' directly
                return "g";
            } else {
                return mappedName;
            }
        }
        
        // GLOBAL FIX: Try global struct method mapping if we're compiling a struct method
        if (originalName == "_this" && compiler.isCompilingStructMethod) {
            var globalMappedName = compiler.globalStructParameterMap.get("_this");
            if (globalMappedName != null) {
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ✓ GLOBAL STRUCT MAPPING: ${originalName} -> ${globalMappedName}');
                #end
                return globalMappedName;
            }
        }
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] No parameter mapping found for: ${originalName}');
        #end
        
        // Special handling for inline context variables
        if (originalName == "_this" && compiler.hasInlineContext("struct")) {
            #if debug_variable_compiler
            // trace("[XRay VariableCompiler] ✓ INLINE STRUCT CONTEXT DETECTED");
            #end
            return "struct";
        }
        
        // Check if this is a LiveView instance variable that should use socket.assigns
        if (compiler.liveViewInstanceVars != null && compiler.liveViewInstanceVars.exists(originalName)) {
            #if debug_variable_compiler
            // trace("[XRay VariableCompiler] ✓ LIVEVIEW INSTANCE VARIABLE DETECTED");
            #end
            var snakeCaseName = NamingHelper.toSnakeCase(originalName);
            return 'socket.assigns.${snakeCaseName}';
        }
        
        // CRITICAL FIX: Check if this variable was renamed during declaration
        // This ensures consistency between TVar and TLocal for ALL variables that go through transformation
        // This includes: _g variables, tempString -> temp_string, camelCase -> snake_case, etc.
        if (compiler.variableRenameMap != null) {
            var renamedName = compiler.variableRenameMap.get(originalName);
            if (renamedName != null) {
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ✓ USING TRACKED RENAME: ${originalName} -> ${renamedName}');
                #end
                // Use the renamed variable directly
                return renamedName;
            }
        }
        
        // CRITICAL FIX: If no rename mapping exists but this is a temp variable, apply snake_case transformation
        // This handles cases where temp variables are referenced before being declared
        if (originalName.indexOf("temp") == 0 && originalName.charAt(4) >= 'A' && originalName.charAt(4) <= 'Z') {
            // This is a tempXxx variable that should be snake_cased
            var snakeCaseName = NamingHelper.toSnakeCase(originalName);
            if (snakeCaseName != originalName) {
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ⚠️ TEMP VARIABLE WITHOUT MAPPING: Applying snake_case: ${originalName} -> ${snakeCaseName}');
                #end
                
                // Track this transformation for future references
                if (compiler.variableRenameMap == null) {
                    compiler.variableRenameMap = new Map<String, String>();
                }
                compiler.variableRenameMap.set(originalName, snakeCaseName);
                
                return snakeCaseName;
            }
        }
        
        // Context-aware mappings (LiveView, struct updates, function references)
        // These are preserved from the original implementation
        
        // Check if this is a function reference being passed as an argument
        if (compiler.isFunctionReference(v, originalName)) {
            #if debug_variable_compiler
            // trace("[XRay VariableCompiler] ✓ FUNCTION REFERENCE DETECTED");
            #end
            return compiler.generateFunctionReference(originalName);
        }
        
        
        // Use parameter mapping if available (for both abstract methods and regular functions with standardized arg names)
        // BUT SKIP if this is a plain 'g' variable that would be mapped to a counter
        var shouldUseParameterMapping = compiler.currentFunctionParameterMap.exists(originalName) &&
            !(originalName == "g" && StringTools.endsWith(compiler.currentFunctionParameterMap.get(originalName), "_counter"));
            
        var result = if (shouldUseParameterMapping) {
            #if debug_variable_compiler
            // trace("[XRay VariableCompiler] ✓ PARAMETER MAPPING DETECTED");
            #end
            compiler.currentFunctionParameterMap.get(originalName);
        } else if (originalName == "_this" && compiler.isCompilingStructMethod && compiler.globalStructParameterMap.exists("_this")) {
            // GLOBAL FIX: Use global struct method mapping when local is not available
            #if debug_variable_compiler
            // trace("[XRay VariableCompiler] ✓ GLOBAL STRUCT MAPPING DETECTED");
            #end
            compiler.globalStructParameterMap.get("_this");
        } else {
            // Debug for camelCase variables
            if (originalName == "bulkAction" || originalName == "alertLevel") {
                // trace('[XRay VariableCompiler] ⚠️ CAMELCASE VARIABLE DETECTED: ${originalName}');
                // trace('[XRay VariableCompiler] No mapping found, converting to snake_case');
            }
            NamingHelper.toSnakeCase(originalName);
        }
        
        /**
         * CRITICAL FIX: Override result with VariableMappingManager if available
         * 
         * WHY: Multiple compiler components were independently managing variable mappings,
         *      causing inconsistencies. The VariableMappingManager centralizes this logic
         *      and prevents undefined variable errors from mapping conflicts.
         *      
         * WHAT: Apply centralized variable transformation that overrides any local mappings
         *       to ensure consistency across all compilation phases.
         *       
         * HOW: Check if VariableMappingManager is available and use its transformVariableName
         *      method to get the authoritative variable name mapping. This includes:
         *      - Array desugaring variable mappings (_g -> g_array)
         *      - Consistent underscore removal and snake_case conversion
         *      - Prevention of problematic mappings (g -> g_counter)
         */
        if (compiler.variableMappingManager != null) {
            var managedResult = compiler.variableMappingManager.transformVariableName(originalName);
            #if debug_variable_compiler
            // trace("[XRay VariableCompiler] ✓ OVERRIDING with VariableMappingManager: ${result} -> ${managedResult}");
            #end
            result = managedResult;
        }
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] Generated local variable: ${result}');
        // trace("[XRay VariableCompiler] LOCAL VARIABLE COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile TVar variable declaration expressions
     * 
     * WHY: Variable declarations require complex handling for optimizations and collision resolution
     * 
     * WHAT: Transform Haxe variable declarations to proper Elixir variable assignments
     * 
     * HOW:
     * 1. Check for unused variable optimization
     * 2. CRITICAL: Detect array desugaring patterns and use VariableMappingManager
     * 3. Resolve variable name collisions in desugared code
     * 4. Handle _this inline context management
     * 5. Generate appropriate Elixir variable assignment
     * 6. Optimize temporary variable elimination
     * 7. CRITICAL: Skip intermediate 'g' variables for enum extraction
     * 
     * @param tvar The TVar representing the variable
     * @param expr The initialization expression (nullable)
     * @return Compiled Elixir variable declaration
     */
    public function compileVariableDeclaration(tvar: TVar, expr: Null<TypedExpr>): String {
        #if debug_variable_compiler
        // trace("[XRay VariableCompiler] VARIABLE DECLARATION COMPILATION START");
        // trace('[XRay VariableCompiler] Variable: ${tvar.name}');
        // trace('[XRay VariableCompiler] Has initialization: ${expr != null}');
        if (expr != null) {
            // trace('[XRay VariableCompiler] Init expression type: ${Type.enumConstructor(expr.expr)}');
            // trace('[XRay VariableCompiler] Full init expression: ${Std.string(expr.expr)}');
        }
        
        // Special debug for problematic variables
        if (StringTools.contains(tvar.name, "temp_array") || StringTools.contains(tvar.name, "args")) {
            // trace("[XRay VariableCompiler] ⚠️ SPECIAL DEBUG: Processing problematic variable " + tvar.name);
            if (expr != null) {
                // trace("[XRay VariableCompiler] ⚠️ SPECIAL DEBUG: Expression details:");
                // trace("[XRay VariableCompiler] ⚠️ SPECIAL DEBUG: - Type: " + Type.enumConstructor(expr.expr));
                // trace("[XRay VariableCompiler] ⚠️ SPECIAL DEBUG: - Full: " + Std.string(expr.expr));
            }
        }
        #end
        
        /**
         * ARCHITECTURAL FIX: Register ID mapping at TVar creation time
         * 
         * WHY: When Haxe desugars switch(Type.typeof()), it creates a TVar named 'g' or '_g'
         *      that should be mapped to 'g_array' for array operations. Previously, we only
         *      set name-based mappings which weren't checked during TLocal compilation.
         * 
         * WHAT: Register the TVar.id → g_array mapping immediately when the variable is
         *       declared, ensuring all future TLocal references use the correct name.
         * 
         * HOW: Check if this is a 'g' variable from switch desugaring and register the
         *      ID mapping before any compilation happens.
         * 
         * @see docs/03-compiler-development/G_ARRAY_MISMATCH_ISSUE.md
         */
        var originalName = getOriginalVarName(tvar);
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] Checking if ${originalName} needs array mapping...');
        // trace('[XRay VariableCompiler] Has init expr: ${expr != null}');
        if (expr != null) {
            // trace('[XRay VariableCompiler] Init expr type: ${Type.enumConstructor(expr.expr)}');
        }
        #end
        
        // SIMPLIFIED FIX: Always register ID mapping for 'g' variables
        // The name-based mapping is already set up by VariableMappingManager
        // We just need to ensure the ID mapping is also registered
        if ((originalName == "g" || originalName == "_g")) {
            // Check if there's already a name-based mapping for this variable
            var existingMapping = compiler.currentFunctionParameterMap.get(originalName);
            
            if (existingMapping != null && existingMapping != originalName) {
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ✓ FOUND EXISTING MAPPING FOR g VARIABLE: ${originalName} → ${existingMapping}');
                // trace('[XRay VariableCompiler] REGISTERING ID MAPPING IMMEDIATELY');
                #end
                
                // Register the ID mapping to ensure consistency
                registerVariableMapping(tvar, existingMapping);
                
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ✓ ID MAPPING REGISTERED: TVar.id ${tvar.id} → ${existingMapping}');
                #end
            }
        }
        
        // Check if this is a 'g' variable that needs array mapping
        if ((originalName == "g" || originalName == "_g") && expr != null) {
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] This is a g variable, checking initialization pattern...');
            #end
            
            // Check if the initialization involves Type.typeof or similar patterns
            var needsArrayMapping = false;
            switch (expr.expr) {
                case TCall(e, args):
                    #if debug_variable_compiler
                    // trace('[XRay VariableCompiler] TCall detected, checking if Type.typeof...');
                    // trace('[XRay VariableCompiler] Call target type: ${Type.enumConstructor(e.expr)}');
                    #end
                    
                    // Check if this is a Type.typeof call
                    switch (e.expr) {
                        case TField(typeExpr, fa):
                            var fieldName = switch (fa) {
                                case FStatic(classRef, cf): 
                                    #if debug_variable_compiler
                                    // trace('[XRay VariableCompiler] Static field: ${cf.get().name}');
                                    #end
                                    cf.get().name;
                                case FDynamic(name):
                                    #if debug_variable_compiler  
                                    // trace('[XRay VariableCompiler] Dynamic field: ${name}');
                                    #end
                                    name;
                                case _: 
                                    #if debug_variable_compiler
                                    // trace('[XRay VariableCompiler] Other field access type');
                                    #end
                                    "";
                            };
                            needsArrayMapping = (fieldName == "typeof" || fieldName == "enumIndex");
                            #if debug_variable_compiler
                            // trace('[XRay VariableCompiler] Field name: ${fieldName}, needs mapping: ${needsArrayMapping}');
                            #end
                        case _: 
                            #if debug_variable_compiler
                            // trace('[XRay VariableCompiler] Not a field access');
                            #end
                    }
                case _: 
                    #if debug_variable_compiler
                    // trace('[XRay VariableCompiler] Not a TCall, type is: ${Type.enumConstructor(expr.expr)}');
                    #end
            };
            
            if (needsArrayMapping) {
                var mappedName = "g_array";
                
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ✓ REGISTERING ID MAPPING AT CREATION: ${tvar.name}(id:${tvar.id}) → ${mappedName}');
                #end
                
                // Register the ID mapping immediately
                registerVariableMapping(tvar, mappedName);
                
                // Also ensure name-based mapping for compatibility
                compiler.currentFunctionParameterMap.set(originalName, mappedName);
                compiler.currentFunctionParameterMap.set("_g", mappedName); // Handle both forms
                
                // Note: We'll apply the mapped name later after varName is declared
                
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ✓ Mappings registered successfully');
                // trace('[XRay VariableCompiler] ID map now has: ${[for (id in variableIdMap.keys()) 'id${id}=>${variableIdMap.get(id)}']}');
                #end
            } else {
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] No array mapping needed for this g variable');
                #end
            }
        }
        
        // ARCHITECTURAL FIX: Check for direct array ternary in TVar initialization
        // Pattern: var args = config != null ? [config] : [];
        if (expr != null && StringTools.startsWith(tvar.name, "tempArray")) {
            switch (expr.expr) {
                case TIf(condition, thenExpr, elseExpr) if (thenExpr != null && elseExpr != null):
                    // Check if this is a direct array ternary assignment
                    var isArrayTernary = switch ([thenExpr.expr, elseExpr.expr]) {
                        case [TArrayDecl(_), TArrayDecl(_)]: true;
                        case _: false;
                    };
                    
                    if (isArrayTernary) {
                        // Generate the inline if expression directly
                        var condStr = compiler.compileExpression(condition);
                        var thenStr = compiler.compileExpression(thenExpr);
                        var elseStr = compiler.compileExpression(elseExpr);
                        
                        var directAssignment = 'if ${condStr}, do: ${thenStr}, else: ${elseStr}';
                        
                        #if debug_variable_compiler
                        // trace("[XRay VariableCompiler] ✓ DIRECT ARRAY TERNARY DETECTED!");
                        // trace('[XRay VariableCompiler] Variable: ${tvar.name}');
                        // trace('[XRay VariableCompiler] Direct assignment: ${directAssignment}');
                        #end
                        
                        // Return the direct assignment, bypassing temp variable creation
                        var varName = getOriginalVarName(tvar);
                        return '${varName} = ${directAssignment}';
                    }
                case _:
            }
        }
        
        // CRITICAL FIX: Detect array desugaring patterns and set up proper mappings
        // This fixes the core issue where Haxe desugars array.map() into variables like _g, _g_array, _g_counter
        // and we need to establish the correct semantic mappings before compilation proceeds
        if (compiler.variableMappingManager != null && compiler.variableMappingManager.isArrayDesugaringVariable(tvar.name)) {
            var baseName = compiler.variableMappingManager.getDesugaringBaseName(tvar.name);
            // trace('[XRay VariableCompiler] ✓ ARRAY DESUGARING DETECTED: ${tvar.name} -> base: ${baseName}');
            
            // Set up the correct mappings for this desugaring pattern
            compiler.variableMappingManager.setupArrayDesugatingMappings(baseName);
            // trace('[XRay VariableCompiler] ✓ Array desugaring mappings established for base: ${baseName}');
        }
        
        // Debug: Always trace 'g' variables to understand the pattern
        if (tvar.name == "g") {
//             trace('[DEBUG] Found g variable! Init expr: ${expr != null ? Type.enumConstructor(expr.expr) : "null"}');
        }
        
        // CRITICAL FIX: Handle enum parameter extraction specially
        // When we see: g = TEnumParameter(...), we need to handle multiple extractions correctly
        if (tvar.name == "g" && expr != null) {
            switch (expr.expr) {
                case TEnumParameter(enumExpr, enumField, index):
                    #if debug_variable_compiler
                    // trace("[XRay VariableCompiler] ✓ ENUM PARAMETER EXTRACTION DETECTED");
                    // trace('[XRay VariableCompiler] Enum field: ${enumField.name}, Index: ${index}');
                    #end
                    
                    // Generate a unique variable name for each extraction
                    // This prevents overwriting when there are multiple parameters
                    var uniqueVarName = 'g_param_${index}';
                    
                    // Track this extraction in a list (there can be multiple)
                    if (compiler.enumExtractionVars == null) {
                        compiler.enumExtractionVars = [];
                    }
                    compiler.enumExtractionVars.push({index: index, varName: uniqueVarName});
                    
                    // Also keep track of the current extraction index for the next TLocal(g) reference
                    compiler.currentEnumExtractionIndex = index;
                    
                    // Compile the extraction with the unique variable name
                    var compiledExtraction = compiler.compileExpression(expr);
                    return '${uniqueVarName} = ${compiledExtraction}';
                case _:
            }
        }
        
        // ARCHITECTURAL FIX: Handle tempArray variables with null initialization
        // These are created by Haxe for ternary expressions in switch cases
        // Pattern: TVar(tempArray, null) followed by standalone TIf, then assignment
        var isTempArrayVariable = expr == null && (
            StringTools.startsWith(tvar.name, "tempArray") ||
            StringTools.startsWith(tvar.name, "temp_array") ||
            (StringTools.startsWith(tvar.name, "temp") && (StringTools.contains(tvar.name, "Array") || StringTools.contains(tvar.name, "array")))
        );
        
        if (isTempArrayVariable) {
            // trace("[XRay VariableCompiler] ⚠️ DETECTED TEMP ARRAY WITH NULL INIT: " + tvar.name);
            // trace("[XRay VariableCompiler] This is likely part of a ternary pattern that needs special handling");
            
            // Skip generating the nil declaration - it will be handled by TLocal compilation
            // when the actual assignment happens. This prevents generating undefined variable references.
            return "";
        }
        
        // Check if variable is marked as unused by optimizer
        var isUnused = tvar.meta != null && tvar.meta.has("-reflaxe.unused");
        if (isUnused) {
            #if debug_variable_compiler
            // trace("[XRay VariableCompiler] ✓ VARIABLE MARKED AS UNUSED - Will prefix with underscore");
            #end
            // Don't skip - we'll prefix with underscore below
        }
        
        // Get the original variable name (before Haxe's renaming)
        var originalName = getOriginalVarName(tvar);
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] Original name: ${originalName}');
        #end
        
        // CRITICAL FIX: Detect variable name collision in desugared loops
        // When Haxe desugars map/filter, it may reuse variable names like _g
        // for both the accumulator array and the loop counter
        var originalNameBeforeRename = originalName;
        if (StringTools.startsWith(originalName, "_g")) {
            #if debug_variable_compiler
            // trace("[XRay VariableCompiler] ✓ COLLISION DETECTION FOR _g VARIABLES");
            #end
            // Check if this is an array initialization followed by integer reassignment
            if (expr != null) {
                switch (expr.expr) {
                    case TArrayDecl([]):
                        // This is array initialization - use a different name
                        originalName = originalName + "_array";
                        #if debug_variable_compiler
                        // trace('[XRay VariableCompiler] Renamed to: ${originalName} (array)');
                        #end
                        
                        // CRITICAL FIX: Register the ID mapping immediately
                        // This ensures TLocal references use the same renamed variable
                        registerVariableMapping(tvar, originalName);
                        #if debug_variable_compiler
                        // trace('[XRay VariableCompiler] ✓ REGISTERED ID MAPPING: TVar.id ${tvar.id} → ${originalName}');
                        #end
                    case TConst(TInt(0)):
                        // CRITICAL FIX: Never rename 'g' to 'g_counter' - it's used for enum handling
                        // The 'g' variable is a special case used in switch expression desugaring
                        if (originalName != "g") {
                            // This is counter initialization - use a different name
                            originalName = originalName + "_counter";
                            #if debug_variable_compiler
                            // trace('[XRay VariableCompiler] Renamed to: ${originalName} (counter)');
                            #end
                        } else {
                            #if debug_variable_compiler
                            // trace('[XRay VariableCompiler] ✓ PRESERVED g variable name (not renaming to g_counter)');
                            #end
                        }
                    case _:
                }
                
                // Track the renaming for consistent usage later
                // CRITICAL FIX: Only track renames for _g variables, not plain 'g' variables
                // The plain 'g' variable is used in multiple contexts (counter AND array) in desugared loops
                // and tracking it globally causes variable name collisions
                if (originalName != originalNameBeforeRename && originalNameBeforeRename != "g") {
                    if (compiler.variableRenameMap == null) {
                        compiler.variableRenameMap = new Map<String, String>();
                    }
                    compiler.variableRenameMap.set(originalNameBeforeRename, originalName);
                    #if debug_variable_compiler
                    // trace('[XRay VariableCompiler] Tracked rename: ${originalNameBeforeRename} -> ${originalName}');
                    #end
                }
            }
        }
        
        /**
         * PARAMETER MAPPING CHECK FOR TVAR
         * 
         * WHY: TVar assignments may reference mapped parameters like '_this' -> 'struct'
         * WHAT: Check parameter mapping before deciding variable name
         * HOW: Look up originalName in parameter map and use mapped value if exists
         */
        // Check if there's a parameter mapping for this variable
        var mappedName = compiler.currentFunctionParameterMap.get(originalName);
        
        // CRITICAL FIX: Never use g_counter mapping for plain 'g' variables
        // The 'g' variable is used for switch expression values, not loop counters
        if (originalName == "g" && mappedName != null && StringTools.endsWith(mappedName, "_counter")) {
            // trace('[XRay VariableCompiler] ⚠️ BLOCKING incorrect g -> ${mappedName} mapping in TVar declaration');
            // trace('[XRay VariableCompiler] Ignoring mapping and using original name "g"');
            mappedName = null; // Force to use original name
        }
        
        if (mappedName != null) {
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] ✓ TVAR PARAMETER MAPPING: ${originalName} -> ${mappedName}');
            #end
            
            // CRITICAL ARCHITECTURAL FIX: Register ID mapping when using name-based mapping
            // This ensures TLocal references will find the same mapped name
            registerVariableMapping(tvar, mappedName);
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] ✓ REGISTERED ID MAPPING: TVar.id ${tvar.id} → ${mappedName}');
            // trace('[XRay VariableCompiler] This ensures TLocal will use the same name!');
            #end
            
            // Use the mapped name directly
            var varName = mappedName;
            
            // CRITICAL: Also track underscore prefix when it comes from parameter mapping
            if (StringTools.startsWith(varName, "_") && !StringTools.startsWith(originalName, "_")) {
                underscorePrefixMap.set(originalName, varName);
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ✓ TRACKED UNDERSCORE PREFIX FROM PARAMETER MAPPING: ${originalName} → ${varName}');
                #end
            }
            
            if (expr != null) {
                // CRITICAL FIX: Specifically check for TEnumParameter expressions that might return empty
                var isEnumParameter = switch(expr.expr) {
                    case TEnumParameter(_, _, _): true;
                    case _: false;
                };
                
                // CRITICAL FIX: Handle ternary operators (TIf) in variable declarations
                // This fixes scoping issues where variables assigned inside if-else blocks
                // are not visible outside those blocks in Elixir
                var compiledExpr = switch(expr.expr) {
                    case TIf(condition, thenExpr, elseExpr) if (elseExpr != null):
                        // ALWAYS use inline form for variable initialization with ternary
                        // This ensures the variable is assigned at the correct scope level
                        #if debug_variable_compiler
                        // trace("[XRay VariableCompiler] ✓ TERNARY IN VARIABLE INIT - Using inline form");
                        // trace("[XRay VariableCompiler] Variable name: " + varName);
                        #end
                        
                        // Generate inline if to avoid scoping issues
                        // Pattern: var = if condition, do: value1, else: value2
                        var conditionCode = compiler.compileExpression(condition);
                        var thenCode = compiler.compileExpression(thenExpr);
                        var elseCode = compiler.compileExpression(elseExpr);
                        'if (${conditionCode}), do: ${thenCode}, else: ${elseCode}';
                    case _:
                        // Not a TIf expression, use standard compilation
                        compiler.compileExpression(expr);
                };
                
                // Only skip assignment for TEnumParameter expressions that return empty
                if (isEnumParameter && (compiledExpr == null || compiledExpr == "")) {
                    #if debug_variable_compiler
                    // trace("[XRay VariableCompiler] ✓ EMPTY ENUM PARAMETER - Skipping variable assignment");
                    #end
                    return ""; // Don't generate anything for unused enum parameters
                }
                
                return '${varName} = ${compiledExpr}';
            }
            return varName;
        }
        
        // GLOBAL FIX: Try global struct method mapping if we're compiling a struct method
        if (originalName == "_this" && compiler.isCompilingStructMethod) {
            var globalMappedName = compiler.globalStructParameterMap.get("_this");
            if (globalMappedName != null) {
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ✓ TVAR GLOBAL STRUCT MAPPING: ${originalName} -> ${globalMappedName}');
                #end
                // Use the global mapped name directly
                var varName = globalMappedName;
                
                if (expr != null) {
                    // CRITICAL FIX: Specifically check for TEnumParameter expressions that might return empty
                    var isEnumParameter = switch(expr.expr) {
                        case TEnumParameter(_, _, _): true;
                        case _: false;
                    };
                    
                    // CRITICAL FIX: Handle ternary operators (TIf) in variable declarations
                    // Same fix as above for global struct mapping case
                    var compiledExpr = switch(expr.expr) {
                        case TIf(condition, thenExpr, elseExpr) if (elseExpr != null):
                            // Use inline form for ternary expressions
                            var conditionCode = compiler.compileExpression(condition);
                            var thenCode = compiler.compileExpression(thenExpr);
                            var elseCode = compiler.compileExpression(elseExpr);
                            'if (${conditionCode}), do: ${thenCode}, else: ${elseCode}';
                        case _:
                            compiler.compileExpression(expr);
                    };
                    
                    // Only skip assignment for TEnumParameter expressions that return empty
                    if (isEnumParameter && (compiledExpr == null || compiledExpr == "")) {
                        #if debug_variable_compiler
                        // trace("[XRay VariableCompiler] ✓ EMPTY ENUM PARAMETER - Skipping variable assignment");
                        #end
                        return ""; // Don't generate anything for unused enum parameters
                    }
                    
                    return '${varName} = ${compiledExpr}';
                }
                return varName;
            }
        }
        
        // Check if this is _this and needs special handling
        var preserveUnderscore = false;
        if (originalName == "_this") {
            #if debug_variable_compiler
            // trace("[XRay VariableCompiler] ✓ _THIS VARIABLE SPECIAL HANDLING");
            #end
            // Check if this is an inline expansion of _this = this.someField
            var isInlineThisInit = switch(expr.expr) {
                case TField(e, _): switch(e.expr) {
                    case TConst(TThis): true;
                    case _: false;
                };
                case _: false;
            };
            
            // Also check if we already have an inline context (struct updates)
            var hasExistingContext = compiler.hasInlineContext("struct");
            
            // Preserve _this if it's an inline expansion OR if inline context is already active
            preserveUnderscore = isInlineThisInit || hasExistingContext;
            
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] Inline init: ${isInlineThisInit}, Existing context: ${hasExistingContext}');
            // trace('[XRay VariableCompiler] Preserve underscore: ${preserveUnderscore}');
            #end
        }
        
        var varName = preserveUnderscore ? originalName : NamingHelper.toSnakeCase(originalName);
        
        // CRITICAL FIX: Apply g_array mapping if it was detected earlier
        if ((originalName == "g" || originalName == "_g")) {
            var existingMapping = compiler.currentFunctionParameterMap.get(originalName);
            if (existingMapping == "g_array") {
                // Apply the Type.typeof mapping
                varName = "g_array";
            }
        }
        
        // CRITICAL FIX: Prefix unused variables with underscore
        // In Elixir, unused variables should be prefixed with underscore to avoid warnings
        if (isUnused && !StringTools.startsWith(varName, "_")) {
            var originalVarName = varName;
            varName = "_" + varName;
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] ✓ PREFIXED UNUSED VARIABLE WITH UNDERSCORE: ${varName}');
            #end
            
            // CRITICAL: Track that this TVar ID now maps to an underscore-prefixed name
            // This ensures that when we reference the variable by TVar.id, we get the correct prefixed name
            if (tvar != null && tvar.id != null) {
                variableIdMap.set(tvar.id, varName);
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ✓ TRACKED UNDERSCORE PREFIX IN ID MAP: id ${tvar.id} → ${varName}');
                #end
            }
            
            // ALSO track by name since TVar IDs differ between declaration and reference
            underscorePrefixMap.set(originalVarName, varName);
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] ✓ TRACKED UNDERSCORE PREFIX BY NAME: ${originalVarName} → ${varName}');
            #end
        }
        
        // CRITICAL FIX: Track ALL variable name transformations (not just underscore removal)
        // When toSnakeCase converts:
        // - '_g' to 'g' (underscore removal)
        // - 'bulkAction' to 'bulk_action' (camelCase to snake_case)
        // - 'alertLevel' to 'alert_level' (camelCase to snake_case)
        // - 'tempString' to 'temp_string' (camelCase to snake_case) - CRITICAL FOR JsonPrinter!
        // We MUST track these mappings so TLocal references can find the correct variable
        if (originalName != varName) {
            // Initialize the rename map if needed
            if (compiler.variableRenameMap == null) {
                compiler.variableRenameMap = new Map<String, String>();
            }
            
            // Track this transformation in the variableRenameMap for TLocal lookups
            compiler.variableRenameMap.set(originalName, varName);
            
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] ✓ TRACKED VARIABLE NAME TRANSFORMATION: ${originalName} -> ${varName}');
            // Special debug for problematic variables
            if (originalName.indexOf("temp") == 0) {
                // trace('[XRay VariableCompiler] ⚠️ CRITICAL: Tracked temp variable mapping: ${originalName} -> ${varName}');
            }
            #end
        }
        
        // ARCHITECTURAL FIX: Check if this TVar references a consumed temporary variable
        if (expr != null) {
            switch (expr.expr) {
                case TLocal(v) if (StringTools.startsWith(v.name, "tempArray")):
                    // Check if this temp_array was consumed by array ternary optimization
                    // Convert camelCase tempArray to snake_case temp_array for lookup
                    var snakeCaseName = NamingHelper.toSnakeCase(v.name);
                    if (compiler.consumedTempVariables != null && compiler.consumedTempVariables.exists(snakeCaseName)) {
                        var directAssignment = compiler.consumedTempVariables.get(snakeCaseName);
                        #if debug_variable_compiler
                        // trace("[XRay VariableCompiler] ✓ ARCHITECTURAL FIX: Using consumed temp variable replacement");
                        // trace('[XRay VariableCompiler] Original: ${varName} = ${v.name} (${snakeCaseName})');
                        // trace('[XRay VariableCompiler] Replacement: ${varName} = ${directAssignment}');
                        #end
                        
                        return '${varName} = ${directAssignment}';
                    }
                    
                case _:
            }
        }
        
        // CRITICAL FIX: Check if this variable is being assigned from TLocal(g) which might be an enum extraction
        if (expr != null && compiler.enumExtractionVars != null && compiler.enumExtractionVars.length > 0) {
            switch (expr.expr) {
                case TLocal(v) if (v.name == "g"):
                    #if debug_variable_compiler
                    // trace("[XRay VariableCompiler] ✓ PATTERN VARIABLE ASSIGNMENT FROM g");
                    // trace('[XRay VariableCompiler] Pattern var: ${varName}');
                    // trace('[XRay VariableCompiler] Current extraction index: ${compiler.currentEnumExtractionIndex}');
                    // trace('[XRay VariableCompiler] Available extractions: ${compiler.enumExtractionVars.length}');
                    #end
                    
                    // Use the extraction variables in order
                    // The pattern variables are assigned in the same order as the extractions
                    if (compiler.currentEnumExtractionIndex < compiler.enumExtractionVars.length) {
                        var extractionVar = compiler.enumExtractionVars[compiler.currentEnumExtractionIndex].varName;
                        
                        #if debug_variable_compiler
                        // trace('[XRay VariableCompiler] Using extraction var: ${extractionVar}');
                        #end
                        
                        // Move to next extraction for the next pattern variable
                        compiler.currentEnumExtractionIndex++;
                        return '${varName} = ${extractionVar}';
                    } else {
                        // Fallback if we run out of extractions
                        #if debug_variable_compiler
                        // trace('[XRay VariableCompiler] WARNING: No more extractions available');
                        #end
                        return '${varName} = nil';
                    }
                case _:
            }
        }
        
        if (expr != null) {
            // Check if this is an inline expansion of _this = this.someField
            var isInlineThisInit = originalName == "_this" && switch(expr.expr) {
                case TField(e, _): switch(e.expr) {
                    case TConst(TThis): true;
                    case _: false;
                };
                case _: false;
            };
            
            if (isInlineThisInit) {
                #if debug_variable_compiler
                // trace("[XRay VariableCompiler] ✓ INLINE THIS INITIALIZATION");
                #end
                // Temporarily disable any existing struct context to compile the right side correctly
                var savedContext = compiler.inlineContextMap.get("struct");
                compiler.inlineContextMap.remove("struct");
                
                // CRITICAL FIX: Specifically check for TEnumParameter expressions that might return empty
                var isEnumParameter = switch(expr.expr) {
                    case TEnumParameter(_, _, _): true;
                    case _: false;
                };
                
                var compiledExpr = compiler.compileExpression(expr);
                
                // Only skip assignment for TEnumParameter expressions that return empty
                if (isEnumParameter && (compiledExpr == null || compiledExpr == "")) {
                    #if debug_variable_compiler
                    // trace("[XRay VariableCompiler] ✓ EMPTY ENUM PARAMETER - Skipping struct assignment");
                    #end
                    return ""; // Don't generate anything for unused enum parameters
                }
                
                // Now set the context for future uses - mark struct as active
                compiler.setInlineContext("struct", "active");
                
                // Always use 'struct' for inline expansions instead of '_this'
                return 'struct = ${compiledExpr}';
            } else {
                // CRITICAL FIX: Specifically check for TEnumParameter expressions that might return empty
                var isEnumParameter = switch(expr.expr) {
                    case TEnumParameter(_, _, _): true;
                    case _: false;
                };
                
                // CRITICAL FIX: Handle ternary operators (TIf) in variable declarations
                // This fixes scoping issues where variables assigned inside if-else blocks
                // are not visible outside those blocks in Elixir
                var compiledExpr = switch(expr.expr) {
                    case TIf(condition, thenExpr, elseExpr) if (elseExpr != null):
                        // ALWAYS use inline form for variable initialization with ternary
                        // This ensures the variable is assigned at the correct scope level
                        #if debug_variable_compiler
                        // trace("[XRay VariableCompiler] ✓ TERNARY IN VARIABLE INIT (general case) - Using inline form");
                        // trace("[XRay VariableCompiler] Variable name: " + varName);
                        #end
                        
                        // Generate inline if to avoid scoping issues
                        // Pattern: var = if condition, do: value1, else: value2
                        var conditionCode = compiler.compileExpression(condition);
                        var thenCode = compiler.compileExpression(thenExpr);
                        var elseCode = compiler.compileExpression(elseExpr);
                        'if (${conditionCode}), do: ${thenCode}, else: ${elseCode}';
                    case _:
                        // Not a TIf expression, use standard compilation
                        compiler.compileExpression(expr);
                };
                
                // Only skip assignment for TEnumParameter expressions that return empty
                if (isEnumParameter && (compiledExpr == null || compiledExpr == "")) {
                    #if debug_variable_compiler
                    // trace("[XRay VariableCompiler] ✓ EMPTY ENUM PARAMETER - Skipping variable assignment");
                    #end
                    return ""; // Don't generate anything for unused enum parameters
                }
                
                // If this is _this and we preserved the underscore, activate inline context
                if (originalName == "_this" && preserveUnderscore) {
                    #if debug_variable_compiler
                    // trace("[XRay VariableCompiler] ✓ ACTIVATING INLINE CONTEXT");
                    #end
                    compiler.setInlineContext("struct", "active");
                }
                
                // In case arms, avoid temp variable assignments - return expressions directly
                if (compiler.isCompilingCaseArm && (StringTools.startsWith(originalName, "temp_") || StringTools.startsWith(originalName, "temp"))) {
                    #if debug_variable_compiler
                    // trace("[XRay VariableCompiler] ✓ TEMPORARY VARIABLE OPTIMIZATION");
                    #end
                    return compiledExpr;
                }
                
                var result = '${varName} = ${compiledExpr}';
                
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] Generated variable declaration: ${result}');
                // trace("[XRay VariableCompiler] VARIABLE DECLARATION COMPILATION END");
                #end
                
                return result;
            }
        } else {
            // In case arms, skip temp variable nil assignments completely
            if (compiler.isCompilingCaseArm && (StringTools.startsWith(originalName, "temp_") || StringTools.startsWith(originalName, "temp"))) {
                #if debug_variable_compiler
                // trace("[XRay VariableCompiler] ✓ TEMPORARY NIL OPTIMIZATION");
                #end
                return "nil";
            }
            
            // COORDINATION FIX: Check if this temp variable is already declared to avoid duplicates
            // This coordinates with ControlFlowCompiler and TempVariableOptimizer
            if (StringTools.startsWith(originalName, "temp_") || StringTools.startsWith(originalName, "temp")) {
                // Initialize tracker if needed
                if (compiler.declaredTempVariables == null) {
                    compiler.declaredTempVariables = new Map<String, Bool>();
                }
                
                // Check if already declared
                if (compiler.declaredTempVariables.exists(varName)) {
                    #if debug_variable_compiler
                    // trace('[XRay VariableCompiler] ✓ ALREADY DECLARED: ${varName}, skipping duplicate');
                    #end
                    return ""; // Return empty string to skip this declaration
                } else {
                    // Mark as declared and proceed
                    compiler.declaredTempVariables.set(varName, true);
                    #if debug_variable_compiler
                    // trace('[XRay VariableCompiler] ✓ DECLARING: ${varName} for first time');
                    #end
                }
            }
            
            var result = '${varName} = nil';
            
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] Generated nil declaration: ${result}');
            // trace("[XRay VariableCompiler] VARIABLE DECLARATION COMPILATION END");
            #end
            
            return result;
        }
    }
    
    /**
     * Setup variable mappings for loop desugaring patterns using TVar.id
     * 
     * WHY: Array operations like filter/map are desugared into while loops with
     * multiple variables that have same names but different purposes
     * 
     * WHAT: Maps counter, limit, and temporary variables to unique names using TVar.id
     * 
     * HOW: Analyzes desugaring patterns and assigns distinct names based on context
     */
    public function setupLoopDesugaringMappings(counterVar: TVar, limitVar: TVar): Void {
        // Map counter variable (loop index)
        registerVariableMapping(counterVar, "g_counter");
        
        // Map limit variable (array/collection length) 
        registerVariableMapping(limitVar, "g_array");
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] ✓ LOOP DESUGARING MAPPINGS ESTABLISHED');
        // trace('[XRay VariableCompiler] Counter: TVar.id=${counterVar.id} -> g_counter');
        // trace('[XRay VariableCompiler] Limit: TVar.id=${limitVar.id} -> g_array');
        #end
    }
    
    /**
     * Compile a variable reference (TLocal expression)
     * 
     * VARIABLE REFERENCE COMPILATION WITH ID MAPPING
     * 
     * WHY: When Haxe desugars loops, it creates multiple TVar instances with the same name
     *      but different IDs. TLocal expressions reference these variables by their TVar.
     *      To prevent variable collisions in generated code, we need to map TVar.id to
     *      unique variable names during reference compilation.
     * 
     * WHAT: Compiles TLocal variable references by:
     *       1. Checking TVar.id mappings for custom names (e.g., g_counter, g_array)
     *       2. Applying variable name substitutions if mapped
     *       3. Falling back to snake_case conversion of original name
     * 
     * HOW: Looks up the TVar.id in variableIdMap first. If a mapping exists, uses that
     *      name. Otherwise, converts the variable name to snake_case for Elixir conventions.
     * 
     * EDGE CASES:
     * - Null TVar (shouldn't happen but defensive)
     * - Variables without mappings (normal case)
     * - Special "this" handling (preserved from parent compiler)
     * 
     * @param tvar The TVar being referenced in a TLocal expression
     * @return Compiled variable name for Elixir
     * @since 1.0.0
     */
    public function compileVariableReference(tvar: TVar): String {
        if (tvar == null) {
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] WARNING: Null TVar in compileVariableReference');
            #end
            return "_";
        }
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] VARIABLE REFERENCE COMPILATION');
        // trace('[XRay VariableCompiler] Variable: ${tvar.name} (id: ${tvar.id})');
        // trace('[XRay VariableCompiler] Checking ID mappings...');
        // trace('[XRay VariableCompiler] Available mappings: ${[for (id in variableIdMap.keys()) 'id${id}=>${variableIdMap.get(id)}']}');
        #end
        
        // Check for TVar.id mapping first (highest priority)
        if (variableIdMap.exists(tvar.id)) {
            var mappedName = variableIdMap.get(tvar.id);
            #if debug_variable_compiler
            // trace('[XRay VariableCompiler] ✓ Found ID mapping: ${tvar.name}(${tvar.id}) → ${mappedName}');
            #end
            return mappedName;
        }
        
        // SIMPLE FIX: If this is a 'g' variable and we have a mapping for it, use it
        var originalName = getOriginalVarName(tvar);
        if (originalName == "g" || originalName == "_g") {
            var nameMapping = compiler.currentFunctionParameterMap.get(originalName);
            if (nameMapping == "g_array") {
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ✓ Found name mapping for g: ${originalName} → g_array');
                #end
                return "g_array";
            }
        }
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] No ID mapping found, checking for unused variable metadata');
        #end
        
        // Get original variable name and convert to snake_case
        var varName = NamingHelper.toSnakeCase(originalName);
        
        // CRITICAL FIX: Check if variable has -reflaxe.unused metadata
        // If it does, it was declared with an underscore prefix, so references must use the same prefix
        if (tvar.meta != null && tvar.meta.has("-reflaxe.unused")) {
            if (!StringTools.startsWith(varName, "_")) {
                varName = "_" + varName;
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] ✓ Variable has -reflaxe.unused metadata, adding underscore prefix: ${varName}');
                #end
            }
        }
        
        return varName;
    }
    
    /**
     * Get the original variable name before Haxe's internal renaming
     * Following the pattern from Reflaxe preprocessors
     * 
     * WHY: Haxe compiler may rename variables internally, but we want the original names
     * WHAT: Extract original variable name from TVar metadata if available
     * HOW: Check :realPath metadata first, fallback to variable name
     */
    public function getOriginalVarName(v: TVar): String {
        #if debug_variable_compiler
        // trace("[XRay VariableCompiler] GETTING ORIGINAL VAR NAME");
        // trace('[XRay VariableCompiler] TVar.id: ${v.id}, TVar.name: ${v.name}');
        #end
        
        // Check if the variable has :realPath metadata (following Reflaxe pattern)
        var originalName = v.getNameOrMeta(":realPath");
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] Original name resolved: ${originalName}');
        #end
        
        return originalName;
    }
    
    /**
     * Check if an expression contains a reference to a specific variable
     * 
     * WHY: Variable reference analysis is needed for pipeline optimization and dependency tracking
     * 
     * WHAT: Recursively analyze TypedExpr AST to find variable references
     * 
     * HOW: Pattern match on expression types and recursively check sub-expressions
     * 
     * @param expr The expression to analyze
     * @param variableName The variable name to search for
     * @return True if the expression contains a reference to the variable
     */
    public function containsVariableReference(expr: TypedExpr, variableName: String): Bool {
        #if debug_variable_compiler
        // trace("[XRay VariableCompiler] CHECKING VARIABLE REFERENCE");
        // trace('[XRay VariableCompiler] Looking for variable: ${variableName}');
        // trace('[XRay VariableCompiler] In expression: ${expr.expr}');
        #end
        
        var result = switch(expr.expr) {
            case TLocal(v):
                var found = v.name == variableName;
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] TLocal check: ${v.name} == ${variableName} = ${found}');
                #end
                found;
                
            case TCall(func, args):
                // Check if first argument is the target variable
                if (args.length > 0 && containsVariableReference(args[0], variableName)) {
                    #if debug_variable_compiler
                    // trace("[XRay VariableCompiler] ✓ FOUND in first argument");
                    #end
                    true;
                } else {
                    // Check other arguments and function
                    var foundInFunc = containsVariableReference(func, variableName);
                    var foundInArgs = false;
                    for (arg in args) {
                        if (containsVariableReference(arg, variableName)) {
                            foundInArgs = true;
                            break;
                        }
                    }
                    var found = foundInFunc || foundInArgs;
                    #if debug_variable_compiler
                    if (found) trace("[XRay VariableCompiler] ✓ FOUND in TCall");
                    #end
                    found;
                }
                
            case TBinop(_, e1, e2):
                var found = containsVariableReference(e1, variableName) || containsVariableReference(e2, variableName);
                #if debug_variable_compiler
                if (found) trace("[XRay VariableCompiler] ✓ FOUND in TBinop");
                #end
                found;
                
            case TField(e, _):
                var found = containsVariableReference(e, variableName);
                #if debug_variable_compiler
                if (found) trace("[XRay VariableCompiler] ✓ FOUND in TField");
                #end
                found;
                
            case TParenthesis(e):
                var found = containsVariableReference(e, variableName);
                #if debug_variable_compiler
                if (found) trace("[XRay VariableCompiler] ✓ FOUND in TParenthesis");
                #end
                found;
                
            default:
                #if debug_variable_compiler
                // trace("[XRay VariableCompiler] No variable reference found in expression type");
                #end
                false;
        };
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] Final result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Check if a statement targets a specific variable (used for pipeline detection).
     * Excludes terminal operations that consume but don't transform the variable.
     * 
     * WHY: Pipeline optimization requires identifying statements that transform variables
     * 
     * WHAT: Analyze statement patterns to detect variable transformation vs consumption
     * 
     * HOW: Check for var x = f(x, ...) and x = f(x, ...) patterns while excluding terminal operations
     * 
     * @param stmt The statement to analyze
     * @param variableName The variable name to check for
     * @return True if statement transforms the variable (part of pipeline)
     */
    public function statementTargetsVariable(stmt: TypedExpr, variableName: String): Bool {
        #if debug_variable_compiler
        // trace("[XRay VariableCompiler] STATEMENT TARGETS VARIABLE CHECK");
        // trace('[XRay VariableCompiler] Variable: ${variableName}');
        // trace('[XRay VariableCompiler] Statement: ${stmt.expr}');
        #end
        
        // Skip terminal operations - they consume the variable but aren't part of the pipeline
        if (isTerminalOperation(stmt, variableName)) {
            #if debug_variable_compiler
            // trace("[XRay VariableCompiler] ✓ TERMINAL OPERATION DETECTED - SKIPPING");
            #end
            return false;
        }
        
        var result = switch(stmt.expr) {
            case TVar(v, init) if (init != null):
                // var x = f(x, ...) pattern
                var varName = v.name;
                if (varName == variableName) {
                    // Check if the init expression uses the same variable
                    var found = containsVariableReference(init, variableName);
                    #if debug_variable_compiler
                    // trace('[XRay VariableCompiler] TVar pattern found: ${found}');
                    #end
                    found;
                } else {
                    false;
                }
                
            case TBinop(OpAssign, {expr: TLocal(v)}, right):
                // x = f(x, ...) pattern
                var varName = v.name;
                if (varName == variableName) {
                    // Check if the right side uses the same variable
                    var found = containsVariableReference(right, variableName);
                    #if debug_variable_compiler
                    // trace('[XRay VariableCompiler] TBinop assignment pattern found: ${found}');
                    #end
                    found;
                } else {
                    false;
                }
                
            default:
                false;
        };
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] Statement targets variable result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Check if a statement is a terminal operation that consumes a pipeline variable
     * but doesn't transform it (like Repo.all, Repo.one, etc.)
     * 
     * WHY: Pipeline optimization needs to distinguish transformation vs consumption
     * 
     * WHAT: Identify terminal operations that end pipelines rather than extend them
     * 
     * HOW: Check for known terminal functions and verify they use the target variable
     * 
     * @param stmt The statement to analyze
     * @param variableName The variable name to check for
     * @return True if statement is a terminal operation on the variable
     */
    public function isTerminalOperation(stmt: TypedExpr, variableName: String): Bool {
        #if debug_variable_compiler
        // trace("[XRay VariableCompiler] TERMINAL OPERATION CHECK");
        // trace('[XRay VariableCompiler] Variable: ${variableName}');
        #end
        
        var result = switch(stmt.expr) {
            case TCall(funcExpr, args):
                // Check for Repo operations or other terminal functions
                var funcName = extractFunctionNameFromCall(funcExpr);
                var terminalFunctions = ["Repo.all", "Repo.one", "Repo.get", "Repo.insert", "Repo.update", "Repo.delete"];
                
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] Function name: ${funcName}');
                #end
                
                if (terminalFunctions.indexOf(funcName) >= 0) {
                    // Check if first argument references our variable
                    if (args.length > 0) {
                        var found = containsVariableReference(args[0], variableName);
                        #if debug_variable_compiler
                        // trace('[XRay VariableCompiler] Terminal function uses variable: ${found}');
                        #end
                        found;
                    } else {
                        false;
                    }
                } else {
                    false;
                }
                
            default:
                false;
        };
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] Terminal operation result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Check if an expression (typically from a TReturn) is a terminal operation on a specific variable
     * 
     * WHY: Return statements often contain terminal operations that need special handling
     * 
     * WHAT: Analyze return expressions for terminal pipeline operations
     * 
     * HOW: Similar to isTerminalOperation but focused on expressions rather than statements
     * 
     * @param expr The expression to analyze
     * @param variableName The variable name to check for
     * @return True if expression is a terminal operation on the variable
     */
    public function isTerminalOperationOnVariable(expr: TypedExpr, variableName: String): Bool {
        #if debug_variable_compiler
        // trace("[XRay VariableCompiler] TERMINAL OPERATION ON VARIABLE CHECK");
        // trace('[XRay VariableCompiler] Variable: ${variableName}');
        #end
        
        var result = switch(expr.expr) {
            case TCall(funcExpr, args):
                // Check for Repo operations or other terminal functions
                var funcName = extractFunctionNameFromCall(funcExpr);
                var terminalFunctions = ["Repo.all", "Repo.one", "Repo.get", "Repo.insert", "Repo.update", "Repo.delete"];
                
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] Function name: ${funcName}');
                #end
                
                if (terminalFunctions.indexOf(funcName) >= 0) {
                    // Check if first argument references our variable
                    if (args.length > 0) {
                        var found = containsVariableReference(args[0], variableName);
                        #if debug_variable_compiler
                        // trace('[XRay VariableCompiler] Terminal function uses variable: ${found}');
                        #end
                        found;
                    } else {
                        false;
                    }
                } else {
                    false;
                }
                
            default:
                false;
        };
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] Terminal operation on variable result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Extract function name from a call expression
     * 
     * WHY: Pipeline analysis requires identifying function names for terminal operation detection
     * 
     * WHAT: Parse TypedExpr call expressions to extract qualified function names
     * 
     * HOW: Pattern match on different field access patterns and module references
     * 
     * @param funcExpr The function expression to analyze
     * @return The extracted function name (e.g., "Repo.all", "map", etc.)
     */
    public function extractFunctionNameFromCall(funcExpr: TypedExpr): String {
        #if debug_variable_compiler
        // trace("[XRay VariableCompiler] EXTRACTING FUNCTION NAME FROM CALL");
        // trace('[XRay VariableCompiler] Function expression: ${funcExpr.expr}');
        #end
        
        var result = switch(funcExpr.expr) {
            case TField({expr: TLocal({name: moduleName})}, fa):
                // Module.function pattern (e.g., Repo.all)
                var funcName = switch(fa) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                        cf.get().name;
                    case FDynamic(s):
                        s;
                    case FEnum(_, ef):
                        ef.name;
                };
                var fullName = moduleName + "." + funcName;
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] Module.function pattern: ${fullName}');
                #end
                fullName;
                
            case TField({expr: TTypeExpr(moduleType)}, fa):
                // Type.function pattern (for static calls like Repo.all)
                var result = switch(fa) {
                    case FStatic(classRef, cf):
                        // For static calls, get the module name from the class
                        var moduleName = switch(classRef.get().name) {
                            case "Repo": "Repo";  // Special case for Repo
                            case name: NamingHelper.toSnakeCase(name);
                        };
                        // Convert method name to snake_case for Elixir
                        var methodName = NamingHelper.toSnakeCase(cf.get().name);
                        var fullName = moduleName + "." + methodName;
                        #if debug_variable_compiler
                        // trace('[XRay VariableCompiler] Type.function pattern: ${fullName}');
                        #end
                        fullName;
                    case FInstance(_, _, cf) | FAnon(cf) | FClosure(_, cf):
                        cf.get().name;
                    case FDynamic(s):
                        s;
                    case FEnum(_, ef):
                        ef.name;
                };
                result;
                
            case TLocal({name: funcName}):
                // Simple function call
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] Simple function: ${funcName}');
                #end
                funcName;
                
            case TField(_, fa):
                // Method call without module
                var funcName = switch(fa) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                        cf.get().name;
                    case FDynamic(s):
                        s;
                    case FEnum(_, ef):
                        ef.name;
                };
                #if debug_variable_compiler
                // trace('[XRay VariableCompiler] Method call: ${funcName}');
                #end
                funcName;
                
            default:
                #if debug_variable_compiler
                // trace("[XRay VariableCompiler] Unknown function expression type");
                #end
                "";
        };
        
        #if debug_variable_compiler
        // trace('[XRay VariableCompiler] Final function name: ${result}');
        #end
        
        return result;
    }
    
}

#end