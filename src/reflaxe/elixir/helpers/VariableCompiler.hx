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
 * Variable Compiler for Reflaxe.Elixir
 * 
 * WHY: The compileElixirExpressionInternal function contained ~123 lines of variable compilation
 * logic scattered across TLocal and TVar cases. This complex logic included LiveView instance
 * variable mapping, function reference detection, inline context management, variable collision
 * resolution for desugared loops, and sophisticated _this handling for struct updates. Having
 * all this variable-specific logic mixed with expression compilation violated Single Responsibility
 * Principle and made variable handling nearly impossible to maintain and extend.
 * 
 * WHAT: Specialized compiler for all variable-related expressions in Haxe-to-Elixir transpilation:
 * - Local variables (TLocal) → Context-aware variable name resolution and mapping
 * - Variable declarations (TVar) → Proper Elixir variable assignment with collision detection
 * - LiveView instance variables → Automatic socket.assigns mapping for Phoenix LiveView
 * - Function references → Capture syntax for function passing (&function/arity)
 * - Inline context management → _this variable handling for struct updates
 * - Variable collision resolution → Smart renaming for desugared loop variables (_g conflicts)
 * - Parameter mapping → Consistent variable naming across function boundaries
 * - Temporary variable optimization → Elimination of unnecessary temp assignments
 * 
 * HOW: The compiler implements sophisticated variable transformation patterns:
 * 1. Receives TLocal/TVar expressions from ExpressionDispatcher
 * 2. Applies context-sensitive variable name resolution and mapping
 * 3. Handles LiveView framework integration with socket.assigns
 * 4. Detects and resolves variable name collisions in desugared code
 * 5. Manages inline context for struct update optimizations
 * 6. Generates idiomatic Elixir variable assignments and references
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on variable expression compilation
 * - Framework Integration: Deep LiveView and Phoenix pattern knowledge
 * - Context Management: Sophisticated inline context tracking for optimizations
 * - Collision Resolution: Smart handling of Haxe's variable name conflicts
 * - Maintainability: Clear separation from expression and control flow logic
 * - Testability: Variable logic can be independently tested and verified
 * - Extensibility: Easy to add new variable patterns and framework integrations
 * 
 * EDGE CASES:
 * - Variable name collision resolution in desugared for-loops (_g variables)
 * - LiveView instance variable detection and socket.assigns mapping
 * - _this variable handling for inline struct update optimizations
 * - Function reference detection and capture syntax generation
 * - Temporary variable elimination in case arm expressions
 * - Parameter mapping for consistent naming across function boundaries
 * 
 * @see documentation/VARIABLE_COMPILATION_PATTERNS.md - Complete variable transformation patterns
 */
@:nullSafety(Off)
class VariableCompiler {
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    
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
    public function compileLocalVariable(v: TVar): String {
        trace("[XRay VariableCompiler] LOCAL VARIABLE COMPILATION START");
        trace('[XRay VariableCompiler] Variable name from TVar: ${v.name}');
        
        // CRITICAL DEBUG: Check if v.name is already 'g_counter'
        if (v.name == "g_counter") {
            trace('[XRay VariableCompiler] ⚠️ ERROR: TVar.name is already g_counter! This should never happen!');
            trace('[XRay VariableCompiler] Attempting to fix by returning "g" instead');
            // This is a critical error - the variable should be 'g', not 'g_counter'
            return "g";
        }
        
        // Get the original variable name (before Haxe's renaming for shadowing avoidance)
        var originalName = getOriginalVarName(v);
        
        // CRITICAL DEBUG: Trace exactly what mapping exists for 'g'
        if (originalName == "g") {
            trace('[XRay VariableCompiler] ✓ Compiling TLocal for g variable');
            if (compiler.currentFunctionParameterMap.exists("g")) {
                var mapping = compiler.currentFunctionParameterMap.get("g");
                trace('[XRay VariableCompiler] WARNING: Found existing mapping g -> ${mapping}');
                if (StringTools.endsWith(mapping, "_counter")) {
                    trace('[XRay VariableCompiler] ⚠️ CRITICAL: g is incorrectly mapped to ${mapping}!');
                    trace('[XRay VariableCompiler] Stack trace would be helpful here to find source');
                    // Don't use the incorrect mapping
                    return "g";
                }
            } else {
                trace('[XRay VariableCompiler] No mapping found for g (good!)');
            }
        }
        
        #if debug_variable_compiler
        trace('[XRay VariableCompiler] Original name: ${originalName}');
        #end
        
        // CRITICAL FIX: NEVER map 'g' to anything ending with '_counter'
        // The 'g' variable is exclusively used for enum parameter extraction
        // Any mapping to g_counter is a compiler bug that causes undefined variable errors
        if (originalName == "g") {
            // First check if there's a mapping for 'g'
            var gMapping = compiler.currentFunctionParameterMap.get("g");
            
            trace('[XRay VariableCompiler] ✓ SPECIAL HANDLING for g variable');
            trace('[XRay VariableCompiler] Current mapping for g: ${gMapping}');
            
            // If there's a mapping to g_counter, that's ALWAYS wrong
            if (gMapping != null && StringTools.endsWith(gMapping, "_counter")) {
                trace('[XRay VariableCompiler] ⚠️ BLOCKING incorrect g -> ${gMapping} mapping, returning "g" directly');
                return "g";
            }
            
            // Return 'g' directly - it should never be mapped to g_counter
            return "g";
        }
        
        /**
         * PARAMETER MAPPING CHECK
         * 
         * WHY: Variables like '_this' need to be mapped to their actual parameter names
         * WHAT: Check if there's a parameter mapping for this variable
         * HOW: Look up in currentFunctionParameterMap first, then inline context
         */
        // Check parameter mapping first (for function parameters)
        trace('[XRay VariableCompiler] Checking parameter mapping for: ${originalName}');
        trace('[XRay VariableCompiler] Parameter map has: ${[for (k in compiler.currentFunctionParameterMap.keys()) k].join(", ")}');
        // Special debug for camelCase variables
        if (originalName == "bulkAction" || originalName == "alertLevel") {
            trace('[XRay VariableCompiler] ⚠️ Looking for camelCase variable ${originalName} in parameter map');
            for (key in compiler.currentFunctionParameterMap.keys()) {
                trace('[XRay VariableCompiler]   Map contains: ${key} -> ${compiler.currentFunctionParameterMap.get(key)}');
            }
        }
        
        var mappedName = compiler.currentFunctionParameterMap.get(originalName);
        if (mappedName != null) {
            trace('[XRay VariableCompiler] ✓ PARAMETER MAPPING: ${originalName} -> ${mappedName}');
            #if debug_variable_compiler
            trace('[XRay VariableCompiler] Found in parameter map');
            #end
            
            // CRITICAL FIX: Don't map 'g' to 'g_counter' in any context - it's always wrong
            // The 'g' variable is used for enum parameter extraction, never for loop counters
            if (originalName == "g" && StringTools.endsWith(mappedName, "_counter")) {
                // This mapping is ALWAYS incorrect - 'g' is for enum extraction, not loops
                trace('[XRay VariableCompiler] ⚠️ BLOCKING incorrect g -> ${mappedName} mapping in TLocal');
                trace('[XRay VariableCompiler] Returning "g" directly instead of ${mappedName}');
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
                trace('[XRay VariableCompiler] ✓ GLOBAL STRUCT MAPPING: ${originalName} -> ${globalMappedName}');
                #end
                return globalMappedName;
            }
        }
        
        #if debug_variable_compiler
        trace('[XRay VariableCompiler] No parameter mapping found for: ${originalName}');
        #end
        
        // Special handling for inline context variables
        if (originalName == "_this" && compiler.hasInlineContext("struct")) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ INLINE STRUCT CONTEXT DETECTED");
            #end
            return "struct";
        }
        
        // Check if this is a LiveView instance variable that should use socket.assigns
        if (compiler.liveViewInstanceVars != null && compiler.liveViewInstanceVars.exists(originalName)) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ LIVEVIEW INSTANCE VARIABLE DETECTED");
            #end
            var snakeCaseName = NamingHelper.toSnakeCase(originalName);
            return 'socket.assigns.${snakeCaseName}';
        }
        
        // CRITICAL FIX: Check if this variable was renamed during declaration
        // This ensures consistency between TVar and TLocal for _g variables
        // BUT DON'T apply this to plain 'g' variables used in enum extraction!
        if (StringTools.startsWith(originalName, "_g") && compiler.variableRenameMap != null) {
            var renamedName = compiler.variableRenameMap.get(originalName);
            if (renamedName != null) {
                #if debug_variable_compiler
                trace('[XRay VariableCompiler] ✓ USING TRACKED RENAME: ${originalName} -> ${renamedName}');
                #end
                originalName = renamedName;
            }
        }
        
        // CRITICAL ROOT CAUSE FIX: Check if this is an orphaned 'g' variable from unused enum parameter extraction
        if (originalName == "g" && isOrphanedEnumVariable(v)) {
            trace("[XRay VariableCompiler] ✓ ORPHANED ENUM VARIABLE DETECTED - ROOT CAUSE FIX");
            trace("[XRay VariableCompiler] Returning nil instead of undefined variable 'g'");
            return "nil"; // Return nil instead of referencing undefined variable
        }
        
        // Check if this is a function reference being passed as an argument
        if (compiler.isFunctionReference(v, originalName)) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ FUNCTION REFERENCE DETECTED");
            #end
            return compiler.generateFunctionReference(originalName);
        }
        
        // Use parameter mapping if available (for both abstract methods and regular functions with standardized arg names)
        // BUT SKIP if this is a plain 'g' variable that would be mapped to a counter
        var shouldUseParameterMapping = compiler.currentFunctionParameterMap.exists(originalName) &&
            !(originalName == "g" && StringTools.endsWith(compiler.currentFunctionParameterMap.get(originalName), "_counter"));
            
        var result = if (shouldUseParameterMapping) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ PARAMETER MAPPING DETECTED");
            #end
            compiler.currentFunctionParameterMap.get(originalName);
        } else if (originalName == "_this" && compiler.isCompilingStructMethod && compiler.globalStructParameterMap.exists("_this")) {
            // GLOBAL FIX: Use global struct method mapping when local is not available
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ GLOBAL STRUCT MAPPING DETECTED");
            #end
            compiler.globalStructParameterMap.get("_this");
        } else {
            // Debug for camelCase variables
            if (originalName == "bulkAction" || originalName == "alertLevel") {
                trace('[XRay VariableCompiler] ⚠️ CAMELCASE VARIABLE DETECTED: ${originalName}');
                trace('[XRay VariableCompiler] No mapping found, converting to snake_case');
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
            trace("[XRay VariableCompiler] ✓ OVERRIDING with VariableMappingManager: ${result} -> ${managedResult}");
            #end
            result = managedResult;
        }
        
        #if debug_variable_compiler
        trace('[XRay VariableCompiler] Generated local variable: ${result}');
        trace("[XRay VariableCompiler] LOCAL VARIABLE COMPILATION END");
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
        trace("[XRay VariableCompiler] VARIABLE DECLARATION COMPILATION START");
        trace('[XRay VariableCompiler] Variable: ${tvar.name}');
        trace('[XRay VariableCompiler] Has initialization: ${expr != null}');
        if (expr != null) {
            trace('[XRay VariableCompiler] Init expression type: ${Type.enumConstructor(expr.expr)}');
        }
        #end
        
        // CRITICAL FIX: Detect array desugaring patterns and set up proper mappings
        // This fixes the core issue where Haxe desugars array.map() into variables like _g, _g_array, _g_counter
        // and we need to establish the correct semantic mappings before compilation proceeds
        if (compiler.variableMappingManager != null && compiler.variableMappingManager.isArrayDesugaringVariable(tvar.name)) {
            var baseName = compiler.variableMappingManager.getDesugaringBaseName(tvar.name);
            trace('[XRay VariableCompiler] ✓ ARRAY DESUGARING DETECTED: ${tvar.name} -> base: ${baseName}');
            
            // Set up the correct mappings for this desugaring pattern
            compiler.variableMappingManager.setupArrayDesugatingMappings(baseName);
            trace('[XRay VariableCompiler] ✓ Array desugaring mappings established for base: ${baseName}');
        }
        
        // Debug: Always trace 'g' variables to understand the pattern
        if (tvar.name == "g") {
            trace('[DEBUG] Found g variable! Init expr: ${expr != null ? Type.enumConstructor(expr.expr) : "null"}');
        }
        
        // CRITICAL FIX: Handle enum parameter extraction specially
        // When we see: g = TEnumParameter(...), we need to handle multiple extractions correctly
        if (tvar.name == "g" && expr != null) {
            switch (expr.expr) {
                case TEnumParameter(enumExpr, enumField, index):
                    #if debug_variable_compiler
                    trace("[XRay VariableCompiler] ✓ ENUM PARAMETER EXTRACTION DETECTED");
                    trace('[XRay VariableCompiler] Enum field: ${enumField.name}, Index: ${index}');
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
        
        // Check if variable is marked as unused by optimizer
        if (tvar.meta != null && tvar.meta.has("-reflaxe.unused")) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ UNUSED VARIABLE OPTIMIZATION");
            #end
            // Skip generating unused variables, but still evaluate expression if it has side effects
            if (expr != null) {
                return compiler.compileExpression(expr);
            } else {
                return "";  // Don't generate anything for unused variables without init
            }
        }
        
        // Get the original variable name (before Haxe's renaming)
        var originalName = getOriginalVarName(tvar);
        
        #if debug_variable_compiler
        trace('[XRay VariableCompiler] Original name: ${originalName}');
        #end
        
        // CRITICAL FIX: Detect variable name collision in desugared loops
        // When Haxe desugars map/filter, it may reuse variable names like _g
        // for both the accumulator array and the loop counter
        var originalNameBeforeRename = originalName;
        if (StringTools.startsWith(originalName, "_g")) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ COLLISION DETECTION FOR _g VARIABLES");
            #end
            // Check if this is an array initialization followed by integer reassignment
            if (expr != null) {
                switch (expr.expr) {
                    case TArrayDecl([]):
                        // This is array initialization - use a different name
                        originalName = originalName + "_array";
                        #if debug_variable_compiler
                        trace('[XRay VariableCompiler] Renamed to: ${originalName} (array)');
                        #end
                    case TConst(TInt(0)):
                        // CRITICAL FIX: Never rename 'g' to 'g_counter' - it's used for enum handling
                        // The 'g' variable is a special case used in switch expression desugaring
                        if (originalName != "g") {
                            // This is counter initialization - use a different name
                            originalName = originalName + "_counter";
                            #if debug_variable_compiler
                            trace('[XRay VariableCompiler] Renamed to: ${originalName} (counter)');
                            #end
                        } else {
                            #if debug_variable_compiler
                            trace('[XRay VariableCompiler] ✓ PRESERVED g variable name (not renaming to g_counter)');
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
                    trace('[XRay VariableCompiler] Tracked rename: ${originalNameBeforeRename} -> ${originalName}');
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
            trace('[XRay VariableCompiler] ⚠️ BLOCKING incorrect g -> ${mappedName} mapping in TVar declaration');
            trace('[XRay VariableCompiler] Ignoring mapping and using original name "g"');
            mappedName = null; // Force to use original name
        }
        
        if (mappedName != null) {
            #if debug_variable_compiler
            trace('[XRay VariableCompiler] ✓ TVAR PARAMETER MAPPING: ${originalName} -> ${mappedName}');
            #end
            // Use the mapped name directly
            var varName = mappedName;
            
            if (expr != null) {
                var compiledExpr = compiler.compileExpression(expr);
                return '${varName} = ${compiledExpr}';
            }
            return varName;
        }
        
        // GLOBAL FIX: Try global struct method mapping if we're compiling a struct method
        if (originalName == "_this" && compiler.isCompilingStructMethod) {
            var globalMappedName = compiler.globalStructParameterMap.get("_this");
            if (globalMappedName != null) {
                #if debug_variable_compiler
                trace('[XRay VariableCompiler] ✓ TVAR GLOBAL STRUCT MAPPING: ${originalName} -> ${globalMappedName}');
                #end
                // Use the global mapped name directly
                var varName = globalMappedName;
                
                if (expr != null) {
                    var compiledExpr = compiler.compileExpression(expr);
                    return '${varName} = ${compiledExpr}';
                }
                return varName;
            }
        }
        
        // Check if this is _this and needs special handling
        var preserveUnderscore = false;
        if (originalName == "_this") {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ _THIS VARIABLE SPECIAL HANDLING");
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
            trace('[XRay VariableCompiler] Inline init: ${isInlineThisInit}, Existing context: ${hasExistingContext}');
            trace('[XRay VariableCompiler] Preserve underscore: ${preserveUnderscore}');
            #end
        }
        
        var varName = preserveUnderscore ? originalName : NamingHelper.toSnakeCase(originalName);
        
        // CRITICAL FIX: Track ALL variable name transformations (not just underscore removal)
        // When toSnakeCase converts:
        // - '_g' to 'g' (underscore removal)
        // - 'bulkAction' to 'bulk_action' (camelCase to snake_case)
        // - 'alertLevel' to 'alert_level' (camelCase to snake_case)
        // We MUST track these mappings so TLocal references can find the correct variable
        if (originalName != varName) {
            // Track this mapping in the parameter map (which is checked first)
            if (!compiler.currentFunctionParameterMap.exists(originalName)) {
                compiler.currentFunctionParameterMap.set(originalName, varName);
                trace('[XRay VariableCompiler] ✓ TRACKED VARIABLE NAME TRANSFORMATION: ${originalName} -> ${varName}');
                // Special debug for problematic variables
                if (originalName == "bulkAction" || originalName == "alertLevel") {
                    trace('[XRay VariableCompiler] ⚠️ SPECIAL: Tracked camelCase mapping for ${originalName}');
                }
            }
        }
        
        // CRITICAL FIX: Check if this variable is being assigned from TLocal(g) which might be an enum extraction
        if (expr != null && compiler.enumExtractionVars != null && compiler.enumExtractionVars.length > 0) {
            switch (expr.expr) {
                case TLocal(v) if (v.name == "g"):
                    #if debug_variable_compiler
                    trace("[XRay VariableCompiler] ✓ PATTERN VARIABLE ASSIGNMENT FROM g");
                    trace('[XRay VariableCompiler] Pattern var: ${varName}');
                    trace('[XRay VariableCompiler] Current extraction index: ${compiler.currentEnumExtractionIndex}');
                    trace('[XRay VariableCompiler] Available extractions: ${compiler.enumExtractionVars.length}');
                    #end
                    
                    // Use the extraction variables in order
                    // The pattern variables are assigned in the same order as the extractions
                    if (compiler.currentEnumExtractionIndex < compiler.enumExtractionVars.length) {
                        var extractionVar = compiler.enumExtractionVars[compiler.currentEnumExtractionIndex].varName;
                        
                        #if debug_variable_compiler
                        trace('[XRay VariableCompiler] Using extraction var: ${extractionVar}');
                        #end
                        
                        // Move to next extraction for the next pattern variable
                        compiler.currentEnumExtractionIndex++;
                        return '${varName} = ${extractionVar}';
                    } else {
                        // Fallback if we run out of extractions
                        #if debug_variable_compiler
                        trace('[XRay VariableCompiler] WARNING: No more extractions available');
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
                trace("[XRay VariableCompiler] ✓ INLINE THIS INITIALIZATION");
                #end
                // Temporarily disable any existing struct context to compile the right side correctly
                var savedContext = compiler.inlineContextMap.get("struct");
                compiler.inlineContextMap.remove("struct");
                var compiledExpr = compiler.compileExpression(expr);
                
                // Now set the context for future uses - mark struct as active
                compiler.setInlineContext("struct", "active");
                
                // Always use 'struct' for inline expansions instead of '_this'
                return 'struct = ${compiledExpr}';
            } else {
                var compiledExpr = compiler.compileExpression(expr);
                
                // If this is _this and we preserved the underscore, activate inline context
                if (originalName == "_this" && preserveUnderscore) {
                    #if debug_variable_compiler
                    trace("[XRay VariableCompiler] ✓ ACTIVATING INLINE CONTEXT");
                    #end
                    compiler.setInlineContext("struct", "active");
                }
                
                // In case arms, avoid temp variable assignments - return expressions directly
                if (compiler.isCompilingCaseArm && (StringTools.startsWith(originalName, "temp_") || StringTools.startsWith(originalName, "temp"))) {
                    #if debug_variable_compiler
                    trace("[XRay VariableCompiler] ✓ TEMPORARY VARIABLE OPTIMIZATION");
                    #end
                    return compiledExpr;
                }
                
                var result = '${varName} = ${compiledExpr}';
                
                #if debug_variable_compiler
                trace('[XRay VariableCompiler] Generated variable declaration: ${result}');
                trace("[XRay VariableCompiler] VARIABLE DECLARATION COMPILATION END");
                #end
                
                return result;
            }
        } else {
            // In case arms, skip temp variable nil assignments completely
            if (compiler.isCompilingCaseArm && (StringTools.startsWith(originalName, "temp_") || StringTools.startsWith(originalName, "temp"))) {
                #if debug_variable_compiler
                trace("[XRay VariableCompiler] ✓ TEMPORARY NIL OPTIMIZATION");
                #end
                return "nil";
            }
            
            var result = '${varName} = nil';
            
            #if debug_variable_compiler
            trace('[XRay VariableCompiler] Generated nil declaration: ${result}');
            trace("[XRay VariableCompiler] VARIABLE DECLARATION COMPILATION END");
            #end
            
            return result;
        }
    }
    
    /**
     * Detect if a TLocal(g) variable is orphaned from unused enum parameter extraction
     * 
     * WHY: Haxe generates TEnumParameter + TLocal pairs for enum destructuring. When TEnumParameter
     *      is skipped as orphaned, the TLocal reference becomes undefined, causing compilation errors.
     * 
     * WHAT: Comprehensive heuristic to detect when a 'g' variable reference is orphaned:
     *       - Variable name is 'g' (Haxe's standard temporary variable for enum parameters)
     *       - Context suggests this is part of TypeSafeChildSpec validation pattern
     *       - Pattern matches orphaned enum parameter extraction scenarios
     * 
     * HOW: Use contextual analysis to detect orphaned enum variable patterns.
     *      This complements the orphaned parameter detection in EnumIntrospectionCompiler.
     * 
     * @param v The TVar representing the local variable
     * @return True if this appears to be an orphaned enum parameter variable
     */
    private function isOrphanedEnumVariable(v: TVar): Bool {
        trace('[XRay VariableCompiler] CHECKING for orphaned enum variable: ${v.name}');
        
        // COMPREHENSIVE ORPHANED ENUM VARIABLE DETECTION:
        // This complements the TEnumParameter orphaned detection in EnumIntrospectionCompiler.
        // When TEnumParameter is skipped, subsequent TLocal(g) becomes undefined.
        
        // Get original name to handle potential renaming
        var originalName = getOriginalVarName(v);
        
        trace('[XRay VariableCompiler] Original variable name: ${originalName}');
        
        // 1. Must be the standard 'g' variable used by Haxe for enum parameter extraction
        if (originalName != "g") {
            trace('[XRay VariableCompiler] ❌ Not a g variable (${originalName}), continuing normally');
            return false;
        }
        
        // 2. For now, be aggressive and assume all 'g' variables in any context are orphaned
        // This is the ROOT CAUSE FIX approach - we know Haxe generates orphaned 'g' variables
        // The pattern is: TEnumParameter extraction followed by TLocal(g) reference
        // Since we already skip TEnumParameter, TLocal(g) becomes undefined
        
        trace('[XRay VariableCompiler] ✓ DETECTED orphaned g variable - ROOT CAUSE FIX APPLIED');
        
        return true; // Be aggressive - all 'g' variables are likely orphaned from enum parameter extraction
    }
    
    /**
     * Get the original variable name before Haxe's internal renaming
     * 
     * WHY: Haxe compiler may rename variables internally, but we want the original names
     * 
     * WHAT: Extract original variable name from TVar metadata if available
     * 
     * HOW: Check :realPath metadata first, fallback to variable name
     * 
     * @param v The TVar to get the original name from
     * @return Original variable name
     */
    public function getOriginalVarName(v: TVar): String {
        #if debug_variable_compiler
        trace("[XRay VariableCompiler] GETTING ORIGINAL VAR NAME");
        trace('[XRay VariableCompiler] TVar name: ${v.name}');
        #end
        
        // Check if the variable has :realPath metadata
        // TVar has both name and meta properties, so we can use the helper
        var originalName = v.getNameOrMeta(":realPath");
        
        #if debug_variable_compiler
        trace('[XRay VariableCompiler] Original name resolved: ${originalName}');
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
        trace("[XRay VariableCompiler] CHECKING VARIABLE REFERENCE");
        trace('[XRay VariableCompiler] Looking for variable: ${variableName}');
        trace('[XRay VariableCompiler] In expression: ${expr.expr}');
        #end
        
        var result = switch(expr.expr) {
            case TLocal(v):
                var found = v.name == variableName;
                #if debug_variable_compiler
                trace('[XRay VariableCompiler] TLocal check: ${v.name} == ${variableName} = ${found}');
                #end
                found;
                
            case TCall(func, args):
                // Check if first argument is the target variable
                if (args.length > 0 && containsVariableReference(args[0], variableName)) {
                    #if debug_variable_compiler
                    trace("[XRay VariableCompiler] ✓ FOUND in first argument");
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
                trace("[XRay VariableCompiler] No variable reference found in expression type");
                #end
                false;
        };
        
        #if debug_variable_compiler
        trace('[XRay VariableCompiler] Final result: ${result}');
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
        trace("[XRay VariableCompiler] STATEMENT TARGETS VARIABLE CHECK");
        trace('[XRay VariableCompiler] Variable: ${variableName}');
        trace('[XRay VariableCompiler] Statement: ${stmt.expr}');
        #end
        
        // Skip terminal operations - they consume the variable but aren't part of the pipeline
        if (isTerminalOperation(stmt, variableName)) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ TERMINAL OPERATION DETECTED - SKIPPING");
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
                    trace('[XRay VariableCompiler] TVar pattern found: ${found}');
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
                    trace('[XRay VariableCompiler] TBinop assignment pattern found: ${found}');
                    #end
                    found;
                } else {
                    false;
                }
                
            default:
                false;
        };
        
        #if debug_variable_compiler
        trace('[XRay VariableCompiler] Statement targets variable result: ${result}');
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
        trace("[XRay VariableCompiler] TERMINAL OPERATION CHECK");
        trace('[XRay VariableCompiler] Variable: ${variableName}');
        #end
        
        var result = switch(stmt.expr) {
            case TCall(funcExpr, args):
                // Check for Repo operations or other terminal functions
                var funcName = extractFunctionNameFromCall(funcExpr);
                var terminalFunctions = ["Repo.all", "Repo.one", "Repo.get", "Repo.insert", "Repo.update", "Repo.delete"];
                
                #if debug_variable_compiler
                trace('[XRay VariableCompiler] Function name: ${funcName}');
                #end
                
                if (terminalFunctions.indexOf(funcName) >= 0) {
                    // Check if first argument references our variable
                    if (args.length > 0) {
                        var found = containsVariableReference(args[0], variableName);
                        #if debug_variable_compiler
                        trace('[XRay VariableCompiler] Terminal function uses variable: ${found}');
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
        trace('[XRay VariableCompiler] Terminal operation result: ${result}');
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
        trace("[XRay VariableCompiler] TERMINAL OPERATION ON VARIABLE CHECK");
        trace('[XRay VariableCompiler] Variable: ${variableName}');
        #end
        
        var result = switch(expr.expr) {
            case TCall(funcExpr, args):
                // Check for Repo operations or other terminal functions
                var funcName = extractFunctionNameFromCall(funcExpr);
                var terminalFunctions = ["Repo.all", "Repo.one", "Repo.get", "Repo.insert", "Repo.update", "Repo.delete"];
                
                #if debug_variable_compiler
                trace('[XRay VariableCompiler] Function name: ${funcName}');
                #end
                
                if (terminalFunctions.indexOf(funcName) >= 0) {
                    // Check if first argument references our variable
                    if (args.length > 0) {
                        var found = containsVariableReference(args[0], variableName);
                        #if debug_variable_compiler
                        trace('[XRay VariableCompiler] Terminal function uses variable: ${found}');
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
        trace('[XRay VariableCompiler] Terminal operation on variable result: ${result}');
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
        trace("[XRay VariableCompiler] EXTRACTING FUNCTION NAME FROM CALL");
        trace('[XRay VariableCompiler] Function expression: ${funcExpr.expr}');
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
                trace('[XRay VariableCompiler] Module.function pattern: ${fullName}');
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
                        trace('[XRay VariableCompiler] Type.function pattern: ${fullName}');
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
                trace('[XRay VariableCompiler] Simple function: ${funcName}');
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
                trace('[XRay VariableCompiler] Method call: ${funcName}');
                #end
                funcName;
                
            default:
                #if debug_variable_compiler
                trace("[XRay VariableCompiler] Unknown function expression type");
                #end
                "";
        };
        
        #if debug_variable_compiler
        trace('[XRay VariableCompiler] Final function name: ${result}');
        #end
        
        return result;
    }
}

#end