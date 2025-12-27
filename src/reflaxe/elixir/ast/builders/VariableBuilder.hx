package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.CompilationContext;

using StringTools;

/**
 * VariableBuilder: Handles variable declarations and references
 * 
 * WHY: Separates complex variable logic from ElixirASTBuilder
 * - Reduces ElixirASTBuilder complexity significantly (300+ lines)
 * - Centralizes variable declarations, initialization, and references
 * - Handles special infrastructure variables (g, _g, g1, etc.)
 * 
 * WHAT: Builds ElixirAST nodes for variable operations
 * - TVar declarations with optional initialization
 * - TLocal variable references
 * - Infrastructure variable detection and skipping
 * - Pattern extraction variable handling
 * - Loop and clause context variable resolution
 * 
 * HOW: Complex priority-based variable handling
 * - Detects and handles infrastructure variables
 * - Manages variable initialization patterns
 * - Checks pattern registry for enum extraction vars
 * - Checks clause context for case-local variables
 * - Handles special infrastructure patterns
 */
@:nullSafety(Off)
class VariableBuilder {
    
    /**
     * Build variable declaration with optional initialization
     * 
     * WHY: TVar with init represents variable declarations in Haxe
     * WHAT: Generates ElixirAST for variable assignment or skips infrastructure vars
     * HOW: Analyzes variable patterns and handles special cases
     * 
     * @param v The variable being declared
     * @param init Optional initialization expression
     * @param context Build context with compilation state
     * @return ElixirASTDef for the declaration, or null to skip
     */
    public static function buildVariableDeclaration(v: TVar, init: Null<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        var buildExpression = context.getExpressionBuilder();
        
        #if debug_ast_builder
        // DISABLED: trace('[VarBuilder] Processing declaration: ${v.name} (id: ${v.id})');
        if (init != null) {
            // DISABLED: trace('[VarBuilder] Init type: ${Type.enumConstructor(init.expr)}');
        }
        #end
        
        // Check if this is an infrastructure variable that should be skipped
        if (isInfrastructureVariableToSkip(v.name)) {
            return handleInfrastructureDeclaration(v, init, context);
        }
        
        // Get the proper variable name
        var varName = resolveDeclarationName(v, context);
        
        if (init == null) {
            // Variable declaration without initialization
            // In Elixir, we typically use nil
            return EMatch(PVar(varName), makeAST(ENil));
        }
        
        // Build the initialization expression
        var initAST = buildExpression(init);
        
        if (initAST == null) {
            #if debug_ast_builder
            // DISABLED: trace('[VarBuilder] Init expression returned null for ${v.name}');
            #end
            return null;
        }
        
        // Create the match expression (variable = value)
        return EMatch(PVar(varName), initAST);
    }
    
    /**
     * Check if a variable should be skipped (infrastructure variables)
     * 
     * WHY: Haxe generates temporary variables for internal operations
     * WHAT: Identifies g, _g, g1, _g1, etc. patterns
     * HOW: Pattern matching on variable name
     */
    static function isInfrastructureVariableToSkip(name: String): Bool {
        // Infrastructure variables: g, _g, g followed by numbers, _g followed by numbers
        if (name == "g" || name == "_g") return true;
        
        // Check for g1, g2, etc.
        if (name.length > 1 && name.charAt(0) == 'g') {
            var rest = name.substr(1);
            if (isAllDigits(rest)) return true;
        }
        
        // Check for _g1, _g2, etc.
        if (name.length > 2 && name.substr(0, 2) == "_g") {
            var rest = name.substr(2);
            if (isAllDigits(rest)) return true;
        }
        
        return false;
    }
    
    /**
     * Check if a string contains only digits
     */
    static function isAllDigits(s: String): Bool {
        if (s.length == 0) return false;
        for (i in 0...s.length) {
            var c = s.charCodeAt(i);
            if (c < 48 || c > 57) return false; // Not 0-9
        }
        return true;
    }
    
    /**
     * Handle infrastructure variable declarations
     * 
     * WHY: Infrastructure variables often need special tracking or skipping
     * WHAT: Maps infrastructure vars for switch patterns or skips them
     * HOW: Analyzes init patterns and stores mappings
     */
    static function handleInfrastructureDeclaration(v: TVar, init: Null<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        if (init == null) {
            // Infrastructure variable without init - skip
            return null;
        }
        
        #if debug_infrastructure_vars
        // DISABLED: trace('[Infrastructure Variable] Declaration: ${v.name} = ${Type.enumConstructor(init.expr)}');
        #end
        
        // Track infrastructure variable mappings for switch targets
        switch(init.expr) {
            case TField(obj, fa):
                // Pattern: _g = something.field
                var fieldName = extractFieldName(fa);
                switch(obj.expr) {
                    case TLocal(localVar):
                        // Pattern: _g = msg.type
                        // In switch patterns, this becomes msg_type
                        // Use static methods from VariableAnalyzer
                        var extractedVarName = reflaxe.elixir.ast.analyzers.VariableAnalyzer.toElixirVarName(localVar.name) 
                                              + "_" 
                                              + reflaxe.elixir.ast.NameUtils.toSnakeCase(fieldName);
                        
                        // Store mapping for later use
                        if (context.tempVarRenameMap == null) {
                            context.tempVarRenameMap = new Map<String, String>();
                        }
                        // Store BOTH keys to keep declarations and references consistent.
                        // - Name-based lookup is used when Haxe reuses names with new IDs.
                        // - ID-based lookup is used for stable binder alignment within a scope.
                        context.tempVarRenameMap.set(v.name, extractedVarName);
                        context.tempVarRenameMap.set(Std.string(v.id), extractedVarName);
                        
                        #if debug_infrastructure_vars
                        // DISABLED: trace('[Infrastructure Variable] Mapping ${v.name} -> $extractedVarName');
                        // DISABLED: trace('[Infrastructure Variable FIX] Generating variable binding instead of skipping');
                        #end

                        // FIXED: Don't skip! Generate the variable binding so g is defined
                        // The mapping is for pattern matching optimization, but the variable must exist
                        var buildExpression = context.getExpressionBuilder();
                        var initAST = buildExpression(init);

                        #if debug_infrastructure_vars
                        // DISABLED: trace('[Infrastructure Variable FIX] initAST is ${initAST == null ? "null" : "not null"}');
                        #end

                        if (initAST != null) {
                            var varName = resolveDeclarationName(v, context);
                            #if debug_infrastructure_vars
                            // DISABLED: trace('[Infrastructure Variable FIX] Generating EMatch for $varName');
                            #end
                            return EMatch(PVar(varName), initAST);
                        }

                        #if debug_infrastructure_vars
                        // DISABLED: trace('[Infrastructure Variable FIX] FAILED - initAST was null, returning null');
                        #end
                        return null;
                        
                    default:
                        // Field access on non-local
                }
                
            case TLocal(localVar):
                // Check if assigning from another infrastructure variable
                if (isInfrastructureVariableToSkip(localVar.name)) {
                    // Skip infrastructure variable chains: g1 = g
                    #if debug_infrastructure_vars
                    // DISABLED: trace('[Infrastructure Variable] Skipping chain: ${v.name} = ${localVar.name}');
                    #end
                    return null;
                }
                
            case TEnumParameter(_, _, _):
                // Pattern: g = elem(tuple, index)
                // Usually handled by pattern matching
                #if debug_infrastructure_vars
                // DISABLED: trace('[Infrastructure Variable] TEnumParameter assignment: ${v.name}');
                #end
                // Let it be processed normally for now
                
            default:
                // Other infrastructure variable uses
        }

        // Normalize Haxe's first numbered infrastructure temp (`g1` / `_g1`) to a stable,
        // descriptive binder (`g_value`).
        //
        // WHY:
        // - Haxe commonly uses `_g` for counters and `_g1` for the paired limit/value.
        // - Many later builders/transforms repair/align references to `g_value` for readability,
        //   but if the declaration stays as `_g1` (or gets discarded), we can end up with
        //   undefined-variable errors.
        //
        // HOW:
        // - If no explicit mapping was produced above (e.g., via `.field` extraction),
        //   register a deterministic mapping for this binder so declarations and references
        //   remain aligned.
        if (context != null && (v.name == "g1" || v.name == "_g1")) {
            if (context.tempVarRenameMap == null) context.tempVarRenameMap = new Map<String, String>();
            var idKey = Std.string(v.id);
            if (!context.tempVarRenameMap.exists(idKey) && !context.tempVarRenameMap.exists(v.name)) {
                context.tempVarRenameMap.set(v.name, "g_value");
                context.tempVarRenameMap.set(idKey, "g_value");
            }
        }
        
        // Default: emit the binding so infrastructure locals exist (loop counters, iterator temps, etc).
        // Skipping these can corrupt desugared loop state (e.g. turning `g < len` into `0 < len`).
        var buildExpression = context.getExpressionBuilder();
        var initAST = buildExpression(init);
        if (initAST != null) {
            var varName = resolveDeclarationName(v, context);
            return EMatch(PVar(varName), initAST);
        }
        return null;
    }
    
    /**
     * Extract field name from field access
     */
    static function extractFieldName(fa: FieldAccess): String {
        return switch(fa) {
            case FInstance(_, _, cf): cf.get().name;
            case FStatic(_, cf): cf.get().name;
            case FAnon(cf): cf.get().name;
            case FClosure(_, cf): cf.get().name;
            case FEnum(_, ef): ef.name;
            case FDynamic(s): s;
        };
    }
    
    /**
     * Resolve the variable name for a declaration
     * 
     * WHY: Variables might need underscore prefix or special naming
     * WHAT: Determines the proper name for the declared variable
     * HOW: Checks usage and applies naming conventions
     */
    static function resolveDeclarationName(v: TVar, context: CompilationContext): String {
        // Haxe can produce a local named `__` from source patterns like `var _ = expr`.
        // In Elixir, `__` is reserved for compiler variables (e.g., __MODULE__), so emitting
        // it as a binder produces warnings. Treat it as the wildcard discard instead.
        if (v.name == "__") return "_";

        // If this local was explicitly remapped (e.g., infrastructure extraction temps),
        // ensure we emit the remapped binder name so declarations and references stay aligned.
        //
        // IMPORTANT: This must happen before snake_casing, because the remapped name is
        // already in Elixir form (and may include reserved-keyword escaping like `end_`).
        if (context != null && context.tempVarRenameMap != null) {
            var idKey = Std.string(v.id);
            if (context.tempVarRenameMap.exists(idKey)) {
                return context.tempVarRenameMap.get(idKey);
            }
            if (context.tempVarRenameMap.exists(v.name)) {
                return context.tempVarRenameMap.get(v.name);
            }
        }

        // Convert variable name to snake_case
        var varName = reflaxe.elixir.ast.NameUtils.toSnakeCase(v.name);
        if (varName == "__") return "_";

        // DISABLED: Underscore prefixing logic removed
        // WHY: We don't have complete usage information during AST building
        // The UsageAnalysis pass (HygieneTransforms) will handle this properly
        // with the complete AST, ensuring consistent naming between declarations
        // and references.
        //
        // PREVIOUS ISSUE: Adding underscores during building caused inconsistency:
        // - Declaration: _changeset = ...  (underscore added here)
        // - Reference: changeset           (no underscore in EVar)
        //
        // The UsageAnalysis pass will:
        // 1. Build complete binding usage map
        // 2. Rename BOTH PVar and EVar nodes consistently
        // 3. Only add underscores to truly unused variables

        return varName;
    }
    
    /**
     * Helper to create AST nodes
     */
    static inline function makeAST(def: ElixirASTDef, ?pos: haxe.macro.Expr.Position): ElixirAST {
        return {def: def, metadata: {}, pos: pos};
    }
    
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
        // DISABLED: trace('[AST Builder] TVar: ${tvar.name} (id: ${tvar.id}) -> $variableName');
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
        // DISABLED: trace('[buildLocal] TLocal: ${tvar.name}, constructorArgCtx: ${context.isInConstructorArgContext}');
        var variableName = resolveVariableName(tvar, context);
        
        #if debug_ast_builder
        // DISABLED: trace('[AST Builder] TLocal: ${tvar.name} (id: ${tvar.id}) -> $variableName');
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
     * 3. Check tempVarRenameMap (DUAL-KEY STORAGE - function params, etc.)
     * 4. Check global mappings (future use)
     * 5. Check infrastructure patterns (g_, rec_, etc.)
     * 6. Use default name
     *
     * VISIBILITY: Public to allow other builders (like CallExprBuilder) to resolve
     * variable names consistently when building lambda calls
     */
    public static function resolveVariableName(tvar: TVar, context: CompilationContext): String {
        var tvarId = tvar.id;
        var defaultName = tvar.name;

        // Priority 0: In constructor contexts, check tempVarRenameMap for parameter name mapping
        // WHY: Prevents "replacer2/space2" bug where shadowed parameters are passed to constructors
        // CONTEXT: When a class has fields "replacer" and "space", and a method has parameters
        //          with the same names, Haxe renames the parameters to "replacer2" and "space2"
        //          to avoid shadowing. FunctionBuilder stores the mapping "replacer2" → "replacer"
        //          in tempVarRenameMap. We must check this mapping FIRST before falling back.
        // RESULT: JsonPrinter.new(replacer, space) instead of JsonPrinter.new(replacer2, space2)
        if (context.isInConstructorArgContext) {
            // Check tempVarRenameMap for the mapping (e.g., "replacer2" → "replacer")
            if (context.tempVarRenameMap != null && context.tempVarRenameMap.exists(defaultName)) {
                var mappedName = context.tempVarRenameMap.get(defaultName);
                // DISABLED: trace('[Constructor Args] Found mapping: ${defaultName} -> $mappedName');
                return mappedName;
            }

            // If not in map, strip numeric suffix as fallback
            var strippedName = stripNumericShadowSuffix(defaultName);
            // DISABLED: trace('[Constructor Args] No mapping, stripping suffix: ${defaultName} -> $strippedName');
            return strippedName;
        }

        // Priority 1: Check pattern registry for enum pattern extraction
        if (context.patternVariableRegistry != null && context.patternVariableRegistry.exists(tvarId)) {
            var patternName = context.patternVariableRegistry.get(tvarId);
            #if debug_pattern_variables
            // DISABLED: trace('[Pattern Variable] Using pattern registry mapping: ${tvar.name} (id: $tvarId) -> $patternName');
            #end
            return patternName;
        }

        // Priority 2: Check clause context for case-local variables
        if (context.currentClauseContext != null) {
            #if debug_clause_context
            // DISABLED: trace('[VarBuilder] Checking ClauseContext for TVar: ${tvar.name} (id: $tvarId)');
            #end
            var clauseMapping = context.currentClauseContext.lookupVariable(tvarId);
            if (clauseMapping != null) {
                #if debug_clause_context
                // DISABLED: trace('[Clause Context] Found mapping for ${tvar.name} (id: $tvarId) -> $clauseMapping');
                #end
                return clauseMapping;
            }
            #if debug_clause_context
            // DISABLED: trace('[VarBuilder] No ClauseContext mapping found for ${tvar.name} (id: $tvarId)');
            #end
        } #if debug_clause_context else {
            // DISABLED: trace('[VarBuilder] ClauseContext is NULL for ${tvar.name} (id: $tvarId)');
        } #end

        // Priority 3: Check tempVarRenameMap for function parameters (DUAL-KEY STORAGE)
        // CRITICAL FIX: This is the same pattern that fixed HygieneTransforms
        // FunctionBuilder stores function parameters with BOTH ID and name keys:
        // - context.tempVarRenameMap.set(idKey, finalName);        // ID-based lookup
        // - context.tempVarRenameMap.set(originalName, finalName); // NAME-based lookup
        // This ensures consistency between parameter declarations and references
        if (context.tempVarRenameMap != null) {
            // Try ID-based lookup first (most reliable)
            var idKey = Std.string(tvarId);
            if (context.tempVarRenameMap.exists(idKey)) {
                var mappedName = context.tempVarRenameMap.get(idKey);
                #if debug_hygiene
                // DISABLED: trace('[Dual-Key Storage] Found ID mapping: ${tvar.name} (id: $tvarId) -> $mappedName');
                #end
                return mappedName;
            }

            // Try name-based lookup as fallback
            if (context.tempVarRenameMap.exists(defaultName)) {
                var mappedName = context.tempVarRenameMap.get(defaultName);
                #if debug_hygiene
                // DISABLED: trace('[Dual-Key Storage] Found NAME mapping: ${tvar.name} -> $mappedName');
                #end
                return mappedName;
            }
        }

        // Priority 5: Check for infrastructure variables
        if (isInfrastructureVariable(defaultName)) {
            var infraName = handleInfrastructureVariable(tvar, context);
            if (infraName != null) {
                return infraName;
            }
        }

        // Priority 7: Check if the declaration had underscore prefix
        // CRITICAL: References must match the declaration name exactly
        var varName = reflaxe.elixir.ast.NameUtils.toSnakeCase(defaultName);
        if (context.underscorePrefixedVars != null && context.underscorePrefixedVars.exists(tvarId)) {
            var hasUnderscorePrefix = context.underscorePrefixedVars.get(tvarId) == true;
            if (hasUnderscorePrefix && varName.length > 0 && varName.charAt(0) != "_") {
                varName = "_" + varName;
                #if debug_ast_builder
                // DISABLED: trace('[VarBuilder] Variable reference ${tvar.name} (id: $tvarId) uses underscore: $varName');
                #end
            }
        }

        // Default: Use the converted variable name
        return varName;
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
            // Generated temporaries are preserved as-is unless the compilation context
            // explicitly remaps them (handled elsewhere).
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
        // DISABLED: trace('[Pattern Variable] Registered: var $tvarId -> $patternName');
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
        // DISABLED: trace('[Pattern Variable] Registry cleared');
        #end
    }
    
    /**
     * Strip numeric shadow suffix from parameter names
     *
     * WHY: Haxe adds numeric suffixes (2, 3, etc.) when parameters shadow class fields
     * WHAT: Removes the numeric suffix to get the original parameter name
     * HOW: Pattern matches "name + digits" and strips the digits
     *
     * EXAMPLE:
     * - "replacer2" → "replacer" (shadowed parameter)
     * - "space3" → "space" (shadowed parameter)
     * - "counter" → "counter" (no shadow, unchanged)
     * - "value2extra" → "value2extra" (not pure numeric suffix, unchanged)
     */
    static function stripNumericShadowSuffix(name: String): String {
        var pattern = ~/^(.+?)(\d+)$/;
        if (pattern.match(name)) {
            var base = pattern.matched(1);
            var suffix = pattern.matched(2);
            #if debug_constructor_args
            // DISABLED: trace('[Shadow Strip] $name -> $base (removed suffix: $suffix)');
            #end
            return base;
        }
        return name;
    }
}

#end
