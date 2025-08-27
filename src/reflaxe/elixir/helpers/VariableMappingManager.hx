#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.ElixirCompiler;

/**
 * VariableMappingContext: Tracks the current compilation state for contextual variable transformations
 */
@:structInit
class VariableMappingContext {
    public var currentFunction: Null<String> = null;
    public var currentClass: Null<ClassType> = null;
    public var currentModule: Null<String> = null;
    public var scopeDepth: Int = 0;
    public var loopDepth: Int = 0;
    public var conditionalDepth: Int = 0;
    public var isInLiveViewContext: Bool = false;
    public var isInGenServerContext: Bool = false;
    public var isInSchemaContext: Bool = false;
}

/**
 * VariableDeclarationInfo: Tracks where variables are declared and their usage patterns
 */
@:structInit
class VariableDeclarationInfo {
    public var declaredAtScopeDepth: Int;
    public var declaredInConditional: Bool;
    public var declaredInLoop: Bool;
    public var usedOutsideDeclarationScope: Bool = false;
    public var transformedName: String;
    public var originalName: String;
    public var declarationPoint: Null<Position> = null;
    public var usagePoints: Array<Position> = [];
}

/**
 * VariableMappingManager: Centralized authority for Haxe compiler-generated variable mappings
 * 
 * WHY: Eliminates DRY violations and inconsistencies across compiler components.
 *      Previously, ControlFlowCompiler, EnumIntrospectionCompiler, PatternMatchingCompiler,
 *      and ElixirCompiler all independently managed mappings for variables like 'g', '_g',
 *      '_this', 'struct', leading to inconsistent state and undefined variable errors.
 * 
 * WHAT: Single source of truth for all variable name transformations and mappings.
 *       Handles Haxe's compiler-generated variables (e.g., _g, _g_array, _g_counter)
 *       and provides consistent mappings across the entire compilation process.
 * 
 * HOW: Maintains authoritative mapping state and provides methods to save, restore,
 *      and transform variable names consistently. All compiler components delegate
 *      variable mapping operations to this manager instead of handling them independently.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles variable name mapping and transformation
 * - DRY Principle: Eliminates duplicate mapping logic across multiple components
 * - Consistency: Ensures all components use the same variable transformations
 * - Debugging: Centralized logging and tracing for variable mapping operations
 * - Maintainability: Single location to update variable mapping behavior
 */
@:nullSafety(Off)
class VariableMappingManager {
    var compiler: ElixirCompiler;
    
    // Enhanced context tracking
    public var compilationContext: VariableMappingContext;
    private var variableDeclarations: Map<String, VariableDeclarationInfo>;
    private var scopeCrossingVariables: Array<String>;
    
    // Saved mapping states for restoration
    private var savedMappingStates: Array<Map<String, String>>;
    private var savedContextStates: Array<VariableMappingContext>;
    
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
        this.compilationContext = {
            scopeDepth: 0,
            loopDepth: 0,
            conditionalDepth: 0,
            isInLiveViewContext: false,
            isInGenServerContext: false,
            isInSchemaContext: false
        };
        this.variableDeclarations = new Map();
        this.scopeCrossingVariables = [];
        this.savedMappingStates = [];
        this.savedContextStates = [];
    }
    
    // Track which base names have already been set up to prevent redundant work
    public var setupBaseNames: Map<String, Bool> = new Map<String, Bool>();
    
    /**
     * Set up mappings for Haxe array desugaring variables
     * 
     * WHY: When Haxe desugars array.map(), it creates _g, _g_array, _g_counter variables.
     *      These need consistent mapping where _g refers to the accumulator array.
     * WHAT: Establishes the correct semantic mapping: _g -> g_array (the accumulator)
     * HOW: Updates currentFunctionParameterMap with the correct associations
     * 
     * @param baseVarName The base variable name without underscore (e.g., "g")
     */
    public function setupArrayDesugatingMappings(baseVarName: String): Void {
        // Guard: Skip if we've already set up mappings for this base name
        if (setupBaseNames.exists(baseVarName)) {
            return;
        }
        setupBaseNames.set(baseVarName, true);
        
        // trace('[VariableMappingManager] Setting up array desugaring mappings for base: ${baseVarName}');
        
        // Critical fix: _g should map to g_array (the accumulator), not just g
        compiler.currentFunctionParameterMap.set('_${baseVarName}', '${baseVarName}_array');
        compiler.currentFunctionParameterMap.set('_${baseVarName}_array', '${baseVarName}_array');
        compiler.currentFunctionParameterMap.set('_${baseVarName}_counter', '${baseVarName}_counter');
        
        // Also handle the direct forms (in case underscore was already removed)
        compiler.currentFunctionParameterMap.set(baseVarName, '${baseVarName}_array');
        
        // trace('[VariableMappingManager] ✓ Mappings established:');
        // trace('[VariableMappingManager] - _${baseVarName} -> ${baseVarName}_array');
        // trace('[VariableMappingManager] - _${baseVarName}_array -> ${baseVarName}_array'); 
        // trace('[VariableMappingManager] - _${baseVarName}_counter -> ${baseVarName}_counter');
        // trace('[VariableMappingManager] - ${baseVarName} -> ${baseVarName}_array');
    }
    
    /**
     * Save current mapping state and remove problematic mappings temporarily
     * 
     * WHY: Some compilation phases need clean variable state to avoid conflicts
     * WHAT: Preserves current mappings and provides clean environment for compilation
     * HOW: Stores current state and removes specified mappings from active map
     * 
     * @param variablesToClear Variables to temporarily remove from mapping
     * @return Saved state for restoration
     */
    public function saveAndClearMappings(variablesToClear: Array<String>): Map<String, String> {
        var savedState = new Map<String, String>();
        
        for (varName in variablesToClear) {
            if (compiler.currentFunctionParameterMap.exists(varName)) {
                var mapping = compiler.currentFunctionParameterMap.get(varName);
                savedState.set(varName, mapping);
                compiler.currentFunctionParameterMap.remove(varName);
                // trace('[VariableMappingManager] Temporarily removed: ${varName} -> ${mapping}');
            }
        }
        
        savedMappingStates.push(savedState);
        return savedState;
    }
    
    /**
     * Restore previously saved mapping state
     * 
     * WHY: After temporary mapping clearing, restore the original state
     * WHAT: Restores all mappings from the saved state
     * HOW: Iterates through saved mappings and reapplies them
     * 
     * @param savedState Previously saved mapping state
     */
    public function restoreMappings(savedState: Map<String, String>): Void {
        for (varName => mapping in savedState) {
            // Only restore if it's not a problematic mapping
            if (!StringTools.endsWith(mapping, "_counter") || varName.indexOf("_counter") >= 0) {
                compiler.currentFunctionParameterMap.set(varName, mapping);
                // trace('[VariableMappingManager] Restored: ${varName} -> ${mapping}');
            } else {
                // trace('[VariableMappingManager] Skipped restoring problematic: ${varName} -> ${mapping}');
            }
        }
    }
    
    /**
     * Apply consistent variable name transformation with full contextual awareness
     * 
     * WHY: Ensure all components use the same naming conventions with context-sensitive logic
     * WHAT: Converts Haxe variable names to appropriate Elixir names using compilation context
     * HOW: Applies transformations based on compilation phase, scope, and usage patterns
     * 
     * @param haxeVarName Original Haxe variable name
     * @return Transformed Elixir variable name
     */
    public function transformVariableName(haxeVarName: String): String {
        // trace('[VariableMappingManager] Transforming variable: ${haxeVarName}');
        // trace('[VariableMappingManager] Context - isCompilingCaseArm: ${compiler.isCompilingCaseArm}');
        // trace('[VariableMappingManager] Context - isInLoopContext: ${compiler.isInLoopContext}');
        // trace('[VariableMappingManager] Context - isCompilingStructMethod: ${compiler.isCompilingStructMethod}');
        
        // 1. CHECK EXISTING MAPPING: Highest priority - explicit mappings
        if (compiler.currentFunctionParameterMap.exists(haxeVarName)) {
            var mapped = compiler.currentFunctionParameterMap.get(haxeVarName);
            // trace('[VariableMappingManager] Using existing mapping: ${haxeVarName} -> ${mapped}');
            return mapped;
        }
        
        // 2. CONTEXTUAL TRANSFORMATIONS: Apply context-sensitive logic
        
        // Case arm context - temporary variables might need special handling
        if (compiler.isCompilingCaseArm && isScopeCrossingVariable(haxeVarName)) {
            // trace('[VariableMappingManager] Case arm context - scope-crossing variable detected');
            // In case arms, we need to be more careful about variable declarations
        }
        
        // Loop context - might have different naming needs
        if (compiler.isInLoopContext && isArrayDesugaringVariable(haxeVarName)) {
            var baseName = getDesugaringBaseName(haxeVarName);
            // trace('[VariableMappingManager] Loop context + array desugaring: ${haxeVarName} -> base: ${baseName}');
            // Could potentially set up loop-specific mappings here
        }
        
        // LiveView context - socket assigns need special handling
        if (compiler.liveViewInstanceVars != null && compiler.liveViewInstanceVars.exists(haxeVarName)) {
            // trace('[VariableMappingManager] LiveView instance variable detected');
            var snakeCaseName = NamingHelper.toSnakeCase(haxeVarName);
            return 'socket.assigns.${snakeCaseName}';
        }
        
        // 3. STANDARD TRANSFORMATION: Default case
        var transformed = NamingHelper.toSnakeCase(haxeVarName);
        // trace('[VariableMappingManager] Standard transformation: ${haxeVarName} -> ${transformed}');
        
        return transformed;
    }
    
    /**
     * Detect if a variable name indicates array desugaring pattern
     * 
     * WHY: Identify when Haxe has desugared array operations into while loops
     * WHAT: Recognize patterns like _g, _g_array, _g_counter that indicate desugaring
     * HOW: Pattern matching on variable names and initialization contexts
     * 
     * @param varName Variable name to check
     * @return True if this appears to be part of array desugaring
     */
    public function isArrayDesugaringVariable(varName: String): Bool {
        var hasDesugaringPattern = (varName.charAt(0) == '_' && 
                (varName.indexOf("_array") >= 0 || 
                 varName.indexOf("_counter") >= 0 || 
                 ~/^_g\d*$/.match(varName)));
        
        // CRITICAL FIX: Don't treat enum extraction temporaries as array variables
        // When we're in enum extraction context, _g variables are for parameter extraction,
        // not array loop desugaring
        if (hasDesugaringPattern && compiler.isInEnumExtraction) {
            #if debug_variable_mapping_manager
            // trace('[VariableMappingManager] ⚠️  SKIPPING array desugaring for ${varName} - in enum extraction context');
            #end
            return false;
        }
        
        return hasDesugaringPattern;
    }
    
    /**
     * Get the base variable name from a desugaring variable
     * 
     * WHY: Extract the root variable name from Haxe's generated variants
     * WHAT: Convert _g, _g_array, _g_counter back to base name "g"
     * HOW: Pattern matching and string manipulation
     * 
     * @param desugarVar Desugaring variable name
     * @return Base variable name
     */
    public function getDesugaringBaseName(desugarVar: String): String {
        if (desugarVar.charAt(0) == '_') {
            desugarVar = desugarVar.substr(1);
        }
        
        if (desugarVar.indexOf("_array") >= 0) {
            return desugarVar.substr(0, desugarVar.indexOf("_array"));
        }
        
        if (desugarVar.indexOf("_counter") >= 0) {
            return desugarVar.substr(0, desugarVar.indexOf("_counter"));
        }
        
        return desugarVar;
    }
    
    /**
     * Check if current mappings have conflicts that could cause undefined variables
     * 
     * WHY: Detect situations where mappings could lead to undefined variable errors
     * WHAT: Analyze current mapping state for potential conflicts
     * HOW: Check for inconsistent mappings and missing required associations
     * 
     * @return Array of conflict descriptions, empty if no conflicts
     */
    public function detectMappingConflicts(): Array<String> {
        var conflicts = [];
        
        // Check for g -> g_counter mapping conflicts
        if (compiler.currentFunctionParameterMap.exists("g")) {
            var gMapping = compiler.currentFunctionParameterMap.get("g");
            if (StringTools.endsWith(gMapping, "_counter")) {
                conflicts.push('Problematic "g" -> "${gMapping}" mapping detected');
            }
        }
        
        // Check for missing array accumulator mappings
        for (key => value in compiler.currentFunctionParameterMap) {
            if (key.charAt(0) == '_' && key.indexOf("g") >= 0) {
                var baseName = getDesugaringBaseName(key);
                if (!compiler.currentFunctionParameterMap.exists(baseName)) {
                    conflicts.push('Missing base mapping for desugaring variable: ${key}');
                }
            }
        }
        
        return conflicts;
    }
    
    /**
     * Check if a variable name indicates a scope-crossing temporary variable
     * 
     * WHY: Detect variables that are declared in one scope but referenced in another,
     *      which causes undefined variable errors in Elixir's strict scoping rules
     * WHAT: Identify temp_ variables that need outer scope declaration
     * HOW: Pattern match on variable names that indicate temporary/intermediate values
     * 
     * @param varName Variable name to check
     * @return True if this appears to be a scope-crossing temporary variable
     */
    public function isScopeCrossingVariable(varName: String): Bool {
        // Common patterns for variables that cross scope boundaries
        return (StringTools.startsWith(varName, "temp_") ||
                StringTools.startsWith(varName, "result_") ||
                StringTools.startsWith(varName, "intermediate_") ||
                varName == "temp_array" ||
                varName == "temp_result" ||
                varName == "temp_socket" ||
                varName == "temp_string" ||
                varName == "temp_number");
    }
    
    /**
     * Generate outer scope variable declaration for scope-crossing variables
     * 
     * WHY: Elixir requires variables to be declared in the outermost scope where they'll be used
     * WHAT: Generate proper variable declarations that initialize temp variables as nil
     * HOW: Create declarations for temp variables at function scope level
     * 
     * @param varName Variable that needs outer scope declaration
     * @return Elixir variable declaration or empty string if not needed
     */
    public function generateOuterScopeDeclaration(varName: String): String {
        if (isScopeCrossingVariable(varName)) {
            // trace('[VariableMappingManager] Generated outer scope declaration: ${varName} = nil');
            return '${varName} = nil';
        }
        return "";
    }
    
    /**
     * TARGETED FIX: Analyze function and pre-declare scope-crossing variables
     * 
     * WHY: The current compilation errors are from variables declared in conditional blocks
     *      but referenced outside those blocks. Elixir requires outer scope declaration.
     * WHAT: Scan upcoming expressions to find variables that will cross scope boundaries
     * HOW: Look for patterns like temp_* variables in conditional contexts and pre-declare them
     * 
     * @param functionExpressions All expressions in the current function being compiled
     * @return List of variable declarations that should be added at function start
     */
    public function generateRequiredOuterScopeDeclarations(functionExpressions: Array<haxe.macro.TypedExpr>): Array<String> {
        var declarations = [];
        var scopeCrossingVars = new Map<String, Bool>();
        
        // Scan all expressions to find scope-crossing patterns
        for (expr in functionExpressions) {
            findScopeCrossingVariables(expr, scopeCrossingVars);
        }
        
        // Generate declarations for found variables
        for (varName in scopeCrossingVars.keys()) {
            var declaration = generateOuterScopeDeclaration(varName);
            if (declaration != "") {
                declarations.push(declaration);
                // trace('[VariableMappingManager] Will pre-declare scope-crossing variable: ${varName}');
            }
        }
        
        return declarations;
    }
    
    /**
     * Recursively find variables that cross scope boundaries
     */
    private function findScopeCrossingVariables(expr: haxe.macro.TypedExpr, foundVars: Map<String, Bool>): Void {
        switch (expr.expr) {
            case TVar(tvar, initExpr):
                // Found a variable declaration - check if it's scope-crossing
                if (isScopeCrossingVariable(tvar.name)) {
                    foundVars.set(tvar.name, true);
                }
                if (initExpr != null) {
                    findScopeCrossingVariables(initExpr, foundVars);
                }
                
            case TIf(condExpr, ifExpr, elseExpr):
                // Check all branches of conditional
                findScopeCrossingVariables(condExpr, foundVars);
                findScopeCrossingVariables(ifExpr, foundVars);
                if (elseExpr != null) {
                    findScopeCrossingVariables(elseExpr, foundVars);
                }
                
            case TBlock(exprs):
                // Recursively check all expressions in block
                for (e in exprs) {
                    findScopeCrossingVariables(e, foundVars);
                }
                
            case TLocal(tvar):
                // Found a variable reference - check if it's scope-crossing
                if (isScopeCrossingVariable(tvar.name)) {
                    foundVars.set(tvar.name, true);
                }
                
            default:
                // For other expression types, we'd need to recursively check sub-expressions
                // This is a simplified implementation focusing on the main patterns
        }
    }

    // ============================================================================
    // ENHANCED CONTEXT MANAGEMENT METHODS
    // ============================================================================

    /**
     * Enter a new compilation scope (function, class, conditional, loop)
     * 
     * WHY: Track scope depth to detect scope-crossing variables
     * WHAT: Update context state and save previous state for restoration
     * HOW: Increment scope counters and save mapping state
     */
    public function enterScope(scopeType: String): Void {
        #if debug_variable_mapping
        // trace('[VariableMappingManager] ENTER_SCOPE: ${scopeType} (depth: ${compilationContext.scopeDepth})');
        #end
        
        // Save current context for potential restoration
        savedContextStates.push({
            currentFunction: compilationContext.currentFunction,
            currentClass: compilationContext.currentClass,
            currentModule: compilationContext.currentModule,
            scopeDepth: compilationContext.scopeDepth,
            loopDepth: compilationContext.loopDepth,
            conditionalDepth: compilationContext.conditionalDepth,
            isInLiveViewContext: compilationContext.isInLiveViewContext,
            isInGenServerContext: compilationContext.isInGenServerContext,
            isInSchemaContext: compilationContext.isInSchemaContext
        });
        
        // Update scope counters based on scope type
        compilationContext.scopeDepth++;
        switch (scopeType.toLowerCase()) {
            case "loop" | "while" | "for":
                compilationContext.loopDepth++;
            case "if" | "conditional" | "switch" | "case":
                compilationContext.conditionalDepth++;
            default:
                // General scope increment already handled above
        }
    }

    /**
     * Exit current compilation scope and restore previous context
     * 
     * WHY: Maintain accurate scope depth for variable scoping decisions
     * WHAT: Restore previous context state and clean up scope-specific mappings
     * HOW: Pop saved context and decrement scope counters
     */
    public function exitScope(scopeType: String): Void {
        #if debug_variable_mapping
        // trace('[VariableMappingManager] EXIT_SCOPE: ${scopeType} (depth: ${compilationContext.scopeDepth})');
        #end
        
        if (savedContextStates.length > 0) {
            compilationContext = savedContextStates.pop();
        } else {
            // Fallback - just decrement counters
            compilationContext.scopeDepth = Std.int(Math.max(0, compilationContext.scopeDepth - 1));
            switch (scopeType.toLowerCase()) {
                case "loop" | "while" | "for":
                    compilationContext.loopDepth = Std.int(Math.max(0, compilationContext.loopDepth - 1));
                case "if" | "conditional" | "switch" | "case":
                    compilationContext.conditionalDepth = Std.int(Math.max(0, compilationContext.conditionalDepth - 1));
            }
        }
    }

    /**
     * Track variable declaration with current scope context
     * 
     * WHY: Record where variables are declared to detect scope-crossing usage
     * WHAT: Store declaration info including scope depth and conditional/loop context
     * HOW: Create VariableDeclarationInfo with current context snapshot
     */
    public function trackVariableDeclaration(varName: String, transformedName: String, pos: Null<Position> = null): Void {
        #if debug_variable_mapping
        // trace('[VariableMappingManager] TRACK_DECLARATION: ${varName} -> ${transformedName} at scope depth ${compilationContext.scopeDepth}');
        #end
        
        variableDeclarations.set(varName, {
            declaredAtScopeDepth: compilationContext.scopeDepth,
            declaredInConditional: compilationContext.conditionalDepth > 0,
            declaredInLoop: compilationContext.loopDepth > 0,
            usedOutsideDeclarationScope: false,
            transformedName: transformedName,
            originalName: varName,
            declarationPoint: pos,
            usagePoints: []
        });
    }

    /**
     * Track variable usage and detect scope-crossing patterns
     * 
     * WHY: Identify when variables declared in inner scopes are used in outer scopes
     * WHAT: Compare usage context with declaration context to detect scope violations
     * HOW: Check current scope depth against declaration scope depth
     */
    public function trackVariableUsage(varName: String, pos: Null<Position> = null): Void {
        if (variableDeclarations.exists(varName)) {
            var declInfo = variableDeclarations.get(varName);
            
            // Add usage point
            if (pos != null) {
                declInfo.usagePoints.push(pos);
            }
            
            // Check if used outside declaration scope
            if (compilationContext.scopeDepth < declInfo.declaredAtScopeDepth) {
                #if debug_variable_mapping
                // trace('[VariableMappingManager] SCOPE_CROSSING_DETECTED: ${varName} declared at depth ${declInfo.declaredAtScopeDepth}, used at depth ${compilationContext.scopeDepth}');
                #end
                
                declInfo.usedOutsideDeclarationScope = true;
                if (scopeCrossingVariables.indexOf(varName) == -1) {
                    scopeCrossingVariables.push(varName);
                }
            }
        }
    }

    /**
     * Set framework-specific compilation context
     * 
     * WHY: Different frameworks (Phoenix, GenServer, Ecto) have different variable transformation rules
     * WHAT: Set context flags that influence variable transformation decisions
     * HOW: Update compilation context with framework-specific flags
     */
    public function setFrameworkContext(framework: String): Void {
        #if debug_variable_mapping
        // trace('[VariableMappingManager] SET_FRAMEWORK_CONTEXT: ${framework}');
        #end
        
        switch (framework.toLowerCase()) {
            case "liveview" | "phoenix_live_view":
                compilationContext.isInLiveViewContext = true;
            case "genserver" | "gen_server":
                compilationContext.isInGenServerContext = true;
            case "schema" | "ecto" | "changeset":
                compilationContext.isInSchemaContext = true;
        }
    }

    /**
     * Get list of all scope-crossing variables that need pre-declaration
     * 
     * WHY: Provide list of variables that need outer scope declaration to fix compilation errors
     * WHAT: Return variables that were used outside their declaration scope
     * HOW: Filter tracked variables for scope violations
     */
    public function getScopeCrossingVariables(): Array<String> {
        var result = [];
        for (varName => declInfo in variableDeclarations) {
            if (declInfo.usedOutsideDeclarationScope) {
                result.push(varName);
            }
        }
        return result.concat(scopeCrossingVariables);
    }

    /**
     * Generate comprehensive outer scope declarations for all scope-crossing variables
     * 
     * WHY: Solve all undefined variable errors by pre-declaring variables at function scope
     * WHAT: Generate Elixir variable declarations for all scope-crossing variables
     * HOW: Iterate through tracked variables and generate declarations
     */
    public function generateAllRequiredDeclarations(compiledBody: String = null): Array<String> {
        var declarations = [];
        var processed = new Map<String, Bool>();
        
        // Process tracked scope-crossing variables
        for (varName => declInfo in variableDeclarations) {
            if (declInfo.usedOutsideDeclarationScope && !processed.exists(varName)) {
                var declaration = generateOuterScopeDeclaration(declInfo.transformedName);
                if (declaration != "") {
                    declarations.push(declaration);
                    processed.set(varName, true);
                    #if debug_variable_mapping
                    // trace('[VariableMappingManager] Generated declaration for tracked variable: ${varName} -> ${declInfo.transformedName}');
                    #end
                }
            }
        }
        
        // Process additional scope-crossing variables detected by pattern matching
        for (varName in scopeCrossingVariables) {
            if (!processed.exists(varName)) {
                var transformedName = transformVariableName(varName);
                var declaration = generateOuterScopeDeclaration(transformedName);
                if (declaration != "") {
                    declarations.push(declaration);
                    processed.set(varName, true);
                    #if debug_variable_mapping
                    // trace('[VariableMappingManager] Generated declaration for pattern-detected variable: ${varName} -> ${transformedName}');
                    #end
                }
            }
        }
        
        // IMMEDIATE FIX: Scan compiled body for temp variables (fallback while tracking matures)
        // WHY: Provides immediate fix for current todo-app compilation errors
        // WHAT: Search compiled Elixir code for temp_* variable usage and pre-declare them
        // HOW: Use regex to find temp variable patterns and generate nil declarations
        if (compiledBody != null && declarations.length == 0) {
            var tempVariables = scanCompiledBodyForTempVariables(compiledBody);
            for (varName in tempVariables) {
                if (!processed.exists(varName) && isScopeCrossingVariable(varName)) {
                    var declaration = generateOuterScopeDeclaration(varName);
                    if (declaration != "") {
                        declarations.push(declaration);
                        processed.set(varName, true);
                        #if debug_variable_mapping
                        // trace('[VariableMappingManager] FALLBACK: Generated declaration for scanned temp variable: ${varName}');
                        #end
                    }
                }
            }
        }
        
        return declarations;
    }
    
    /**
     * IMMEDIATE FIX: Scan compiled body for temp variables needing pre-declaration
     * 
     * WHY: While proper AST tracking is being developed, we need an immediate fix
     * WHAT: Extract all temp_* variables from already compiled Elixir code
     * HOW: Use regex patterns to find variable assignments and references
     * 
     * @param compiledBody The compiled Elixir function body
     * @return Array of temp variable names found in the code
     */
    private function scanCompiledBodyForTempVariables(compiledBody: String): Array<String> {
        var tempVars = [];
        var processed = new Map<String, Bool>();
        
        // Pattern to match temp variable assignments: temp_something = 
        var assignmentPattern = ~/temp_\w+ =/g;
        var pos = 0;
        while (assignmentPattern.matchSub(compiledBody, pos)) {
            var match = assignmentPattern.matched(0);
            var varName = match.substring(0, match.length - 2); // Remove " ="
            if (!processed.exists(varName)) {
                tempVars.push(varName);
                processed.set(varName, true);
            }
            pos = assignmentPattern.matchedPos().pos + assignmentPattern.matchedPos().len;
        }
        
        // Pattern to match temp variable usage without assignment
        var usagePattern = ~/temp_\w+/g;
        pos = 0;
        while (usagePattern.matchSub(compiledBody, pos)) {
            var varName = usagePattern.matched(0);
            if (!processed.exists(varName)) {
                tempVars.push(varName);
                processed.set(varName, true);
            }
            pos = usagePattern.matchedPos().pos + usagePattern.matchedPos().len;
        }
        
        #if debug_variable_mapping
        if (tempVars.length > 0) {
            // trace('[VariableMappingManager] Scanned body and found ${tempVars.length} temp variables: [${tempVars.join(", ")}]');
        }
        #end
        
        return tempVars;
    }

    /**
     * Debug method: Get current compilation context status
     * 
     * WHY: Provide visibility into current compilation state for debugging
     * WHAT: Return snapshot of current context with all state information
     * HOW: Return formatted string with all context details
     */
    public function getContextDebugInfo(): String {
        return 'VariableMappingContext: {
    function: ${compilationContext.currentFunction ?? "null"},
    class: ${compilationContext.currentClass?.name ?? "null"},
    module: ${compilationContext.currentModule ?? "null"},
    scopeDepth: ${compilationContext.scopeDepth},
    loopDepth: ${compilationContext.loopDepth},
    conditionalDepth: ${compilationContext.conditionalDepth},
    isInLiveViewContext: ${compilationContext.isInLiveViewContext},
    isInGenServerContext: ${compilationContext.isInGenServerContext},
    isInSchemaContext: ${compilationContext.isInSchemaContext},
    trackedVariables: ${Lambda.count(variableDeclarations)},
    scopeCrossingVariables: ${scopeCrossingVariables.length}
}';
    }
}

#end