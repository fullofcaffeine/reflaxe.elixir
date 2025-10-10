#if (macro || reflaxe_runtime)

package reflaxe.elixir.ast.builders;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import haxe.macro.Context;

import reflaxe.BaseCompiler;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.context.BuildContext;
import reflaxe.elixir.ast.ElixirASTHelpers;
using reflaxe.helpers.NullableMetaAccessHelper;
using reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.TypeHelper;
using StringTools;
using Lambda;
using reflaxe.elixir.ast.NameUtils;
import reflaxe.elixir.helpers.PatternDetector;

/**
 * PatternBuilder: Pattern Matching AST Construction
 * 
 * WHY: Pattern matching is central to Elixir's programming model. This builder handles
 *      the complex transformation from Haxe's switch/case patterns to Elixir's pattern
 *      matching syntax, including enum destructuring, variable binding, and tuple patterns.
 * 
 * WHAT: Converts Haxe TypedExpr patterns to Elixir EPattern AST nodes.
 *       - Enum patterns (both idiomatic and regular)
 *       - Literal patterns (integers, strings, booleans)
 *       - Variable patterns
 *       - Tuple and list patterns
 *       - Underscore prefixing for unused variables
 * 
 * HOW: The builder works in several stages:
 *      1. Pattern Analysis: Detect enum types and extract parameter names
 *      2. Pattern Conversion: Transform TypedExpr to EPattern AST
 *      3. Usage Analysis: Detect unused variables for underscore prefixing
 *      4. Pattern Optimization: Apply idiomatic transformations
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: All pattern-related logic in one place
 * - Testability: Can test pattern matching independently
 * - Performance: Optimized pattern detection and conversion
 * - Maintainability: Clear separation from other AST concerns
 * 
 * EDGE CASES:
 * - Empty case bodies with unused parameters
 * - Complex enum parameter extraction with temp variables
 * - Nested pattern matching
 * - Variable aliasing and temp variable tracking
 */
@:nullSafety(Off)
class PatternBuilder {
    
    // ================================================================
    // Enum-Specific Pattern Functions
    // ================================================================
    
    /**
     * Create binding plan for enum parameters
     * 
     * WHY: Enum constructors like Ok(value) need to bind "value" in the case body.
     *      The plan determines which parameters are actually used to avoid warnings.
     * 
     * WHAT: Analyzes TEnumParameter expressions to understand which enum parameters
     *       are extracted and how they should be bound in the pattern.
     * 
     * HOW: 
     *      1. Identify the enum type and constructor
     *      2. Map TEnumParameter indices to parameter names
     *      3. Create a plan for binding (used vs unused)
     * 
     * EDGE CASES:
     * - Constructors with no parameters (e.g., None)
     * - Complex nested patterns
     * - Wildcard parameters that shouldn't be bound
     */
    public static function createEnumBindingPlan(caseExpr: TypedExpr, 
                                                 extractedParams: Array<String>,
                                                 enumType: Null<EnumType>,
                                                 context: BuildContext): EnumBindingPlan {
        var plan: EnumBindingPlan = {
            enumConstructor: null,
            parameterBindings: [],
            isIdiomatic: false,
            patternExtractedParams: extractedParams.copy()  // Track which params the pattern extracts
        };
        
        // Extract enum information
        switch(caseExpr.expr) {
            case TField(_, FEnum(enumRef, ef)):
                plan.enumConstructor = ef.name;
                plan.isIdiomatic = enumRef.get().meta.has("elixirIdiomatic");
                
                // Get parameter count from enum field type
                var paramCount = 0;
                switch(ef.type) {
                    case TFun(args, _):
                        paramCount = args.length;
                    default:
                        // No parameters
                }
                
                // Create bindings for each parameter
                for (i in 0...paramCount) {
                    var binding: ParameterBinding = {
                        index: i,
                        name: (i < extractedParams.length) ? extractedParams[i] : "_param_" + i,
                        isUsed: false  // Will be determined later
                    };
                    plan.parameterBindings.push(binding);
                }
                
            case TCall(enumExpr, args):
                // Handle constructor calls like Ok(value)
                plan = createEnumBindingPlan(enumExpr, extractedParams, enumType, context);
                
                // Update bindings based on actual arguments
                for (i in 0...args.length) {
                    if (i < plan.parameterBindings.length) {
                        switch(args[i].expr) {
                            case TLocal(v):
                                plan.parameterBindings[i].name = v.name;
                            default:
                                // Keep default name
                        }
                    }
                }
                
            default:
                // Not an enum pattern
        }
        
        return plan;
    }
    
    // ================================================================
    // Main Pattern Conversion Functions
    // ================================================================
    
    /**
     * Convert a TypedExpr to an Elixir pattern
     * 
     * WHY: Switch case values need to be converted to Elixir patterns
     * WHAT: Handles literals, enum constructors, variables, and complex patterns
     * HOW: Analyzes the TypedExpr structure and generates appropriate pattern
     */
    public static function convertPattern(value: TypedExpr, context: BuildContext): EPattern {
        return switch(value.expr) {
            // Literals
            case TConst(TInt(i)): 
                PLiteral(makeAST(EInteger(i)));
            case TConst(TFloat(f)): 
                PLiteral(makeAST(EFloat(Std.parseFloat(f))));
            case TConst(TString(s)): 
                PLiteral(makeAST(EString(s)));
            case TConst(TBool(b)): 
                PLiteral(makeAST(EBoolean(b)));
            case TConst(TNull): 
                PLiteral(makeAST(ENil));
                
            // Variables (for pattern matching)
            case TLocal(v):
                trace('[PatternBuilder.convertPattern] TLocal v.name: ${v.name}, v.id: ${v.id}');
                PVar(ElixirASTHelpers.toElixirVarName(v.name));
                
            // Enum constructors
            case TEnumParameter(e, ef, index):
                // This represents matching against enum constructor arguments
                // We'll need to handle this in the context of the full pattern
                PVar("_enum_param_" + index);
                
            case TEnumIndex(e):
                // Matching against enum index (for switch on elem(tuple, 0))
                PLiteral(makeAST(EInteger(0))); // Will be refined based on actual enum
                
            // Array patterns
            case TArrayDecl(el):
                PList([for (e in el) convertPattern(e, context)]);
                
            // Tuple patterns (for enum matching)
            case TCall(e, el) if (PatternDetector.isEnumConstructor(e)):
                // Enum constructor pattern
                var tag = extractEnumTag(e);
                
                // For idiomatic enums, convert to snake_case
                if (hasIdiomaticMetadata(e)) {
                    tag = tag.toSnakeCase();
                }
                
                var args = [for (arg in el) convertPattern(arg, context)];
                // Create tuple pattern {:tag, arg1, arg2, ...}
                PTuple([PLiteral(makeAST(EAtom(tag)))].concat(args));
                
            // Field access (for enum constructors)
            case TField(e, FEnum(enumRef, ef)):
                convertEnumFieldPattern(ef, [], enumRef.get().meta.has("elixirIdiomatic"), context);
                
            // Default/wildcard
            default: 
                PWildcard;
        }
    }
    
    /**
     * Convert enum field to pattern (handles both idiomatic and regular)
     */
    private static function convertEnumFieldPattern(ef: EnumField, args: Array<TypedExpr>, 
                                                    isIdiomatic: Bool,
                                                    context: BuildContext): EPattern {
        if (isIdiomatic) {
            return convertIdiomaticEnumPattern(ef, args, context);
        } else {
            return convertRegularEnumPattern(ef, args, context);
        }
    }
    
    /**
     * Convert idiomatic enum pattern (uses atom tags)
     */
    private static function convertIdiomaticEnumPattern(ef: EnumField, args: Array<TypedExpr>,
                                                       context: BuildContext): EPattern {
        // Convert enum name to atom
        var atomName = ef.name.toSnakeCase();
        
        if (args.length == 0) {
            // Simple atom
            return PLiteral(makeAST(EAtom(atomName)));
        } else {
            // Tuple with atom tag
            var patterns = [PLiteral(makeAST(EAtom(atomName)))];
            for (arg in args) {
                patterns.push(convertPattern(arg, context));
            }
            return PTuple(patterns);
        }
    }
    
    /**
     * Convert regular enum pattern (uses atom tags, not integer indices)
     */
    private static function convertRegularEnumPattern(ef: EnumField, args: Array<TypedExpr>, 
                                                     context: BuildContext): EPattern {
        // Regular enums should use tuple with atom tag, not integer index
        // Convert enum constructor name to snake_case atom
        var atomName = NameUtils.toSnakeCase(ef.name);
        var patterns = [PLiteral(makeAST(EAtom(atomName)))];
        for (arg in args) {
            patterns.push(convertPattern(arg, context));
        }
        return PTuple(patterns);
    }
    
    // ================================================================
    // Helper Functions
    // ================================================================
    
    /**
     * Extract pattern variable names from case values
     */
    public static function extractPatternVariableNamesFromValues(values: Array<TypedExpr>): Array<String> {
        var patternVars = [];
        
        for (value in values) {
            switch(value.expr) {
                case TCall(e, args):
                    // This is an enum constructor pattern like Ok(email) or Error(reason)
                    // Extract the variable names from the arguments
                    for (i in 0...args.length) {
                        var arg = args[i];
                        switch(arg.expr) {
                            case TLocal(v):
                                // Pattern variable like "email" in Ok(email)
                                var varName = ElixirASTHelpers.toElixirVarName(v.name);
                                // Ensure array is large enough
                                while (patternVars.length <= i) {
                                    patternVars.push(null);
                                }
                                patternVars[i] = varName;
                            default:
                                // Could be a constant or wildcard
                        }
                    }
                default:
                    // Not a constructor pattern
            }
        }
        
        return patternVars;
    }
    
    /**
     * Analyze enum parameter extraction from switch cases
     * 
     * WHY: When we have enum patterns like Ok(email) or Error(reason), we need to know
     *      what parameters are being extracted so we can generate correct patterns.
     * 
     * WHAT: Analyzes the case expression to extract parameter names from enum constructors
     * 
     * HOW: Looks for TCall patterns with enum constructors and extracts variable names
     */
    public static function analyzeEnumParameterExtraction(caseExpr: TypedExpr, caseValues: Array<TypedExpr> = null): Array<String> {
        var extractedParams = [];
        
        // First check if we have explicit parameter names in the case values
        if (caseValues != null && caseValues.length > 0) {
            extractedParams = extractPatternVariableNamesFromValues(caseValues);
            if (extractedParams.length > 0) {
                return extractedParams;
            }
        }
        
        // If no explicit names found, try to infer from the case expression
        switch(caseExpr.expr) {
            case TCall(e, args):
                // Enum constructor with arguments
                for (i in 0...args.length) {
                    var arg = args[i];
                    switch(arg.expr) {
                        case TLocal(v):
                            extractedParams.push(ElixirASTHelpers.toElixirVarName(v.name));
                        default:
                            extractedParams.push("_param_" + i);
                    }
                }
                
            case TField(_, FEnum(_, ef)):
                // Just the enum constructor without arguments
                // Check the enum field type to see how many parameters it expects
                switch(ef.type) {
                    case TFun(args, _):
                        // Create default parameter names
                        for (i in 0...args.length) {
                            extractedParams.push("_param_" + i);
                        }
                    default:
                        // No parameters
                }
                
            default:
                // Not an enum pattern
        }
        
        return extractedParams;
    }
    
    /**
     * Convert pattern with extraction support
     */
    public static function convertPatternWithExtraction(value: TypedExpr, extractedParams: Array<String>, context: BuildContext): EPattern {
        return switch(value.expr) {
            // Most cases delegate to regular convertPattern
            case TConst(_) | TLocal(_) | TArrayDecl(_) | TEnumIndex(_):
                convertPattern(value, context);
                
            // Enum constructors - the main difference
            case TCall(e, el) if (PatternDetector.isEnumConstructor(e)):
                convertEnumConstructorWithExtraction(e, el, extractedParams, context);
                
            // Field access (for enum constructors without arguments)
            case TField(e, FEnum(enumRef, ef)):
                convertEnumFieldWithExtraction(ef, extractedParams, enumRef.get(), context);
                
            default:
                // Fall back to regular pattern conversion
                convertPattern(value, context);
        }
    }
    
    public static function convertIdiomaticEnumPatternWithExtraction(value: TypedExpr, enumType: EnumType, 
                                                                    ef: EnumField, extractedParams: Array<String>,
                                                                    context: BuildContext): EPattern {
        // Implementation for idiomatic enum pattern with extraction
        return convertIdiomaticEnumPattern(ef, [], context);
    }
    
    public static function convertRegularEnumPatternWithExtraction(value: TypedExpr, enumType: EnumType,
                                                                  ef: EnumField, extractedParams: Array<String>,
                                                                  context: BuildContext): EPattern {
        // Implementation for regular enum pattern with extraction
        return convertRegularEnumPattern(ef, [], context);
    }
    
    /**
     * Convert enum constructor with extracted parameters
     */
    private static function convertEnumConstructorWithExtraction(e: TypedExpr, el: Array<TypedExpr>,
                                                                extractedParams: Array<String>,
                                                                context: BuildContext): EPattern {
        // Enum constructor pattern with extracted parameter names
        var tag = extractEnumTag(e);

        // For idiomatic enums, convert to snake_case
        if (hasIdiomaticMetadata(e)) {
            tag = tag.toSnakeCase();
        }

        // Use extracted parameter names instead of wildcards or generic names
        var args = [];
        for (i in 0...el.length) {
            if (i < extractedParams.length && extractedParams[i] != null) {
                // Use the user-specified variable name
                args.push(PVar(extractedParams[i]));

                // CRITICAL FIX: Populate enumBindingPlan so TEnumParameter knows this was extracted
                // Cast to CompilationContext to access currentClauseContext property
                var compilationCtx = cast(context, reflaxe.elixir.CompilationContext);
                if (compilationCtx != null && compilationCtx.currentClauseContext != null) {
                    compilationCtx.currentClauseContext.enumBindingPlan.set(i, {
                        finalName: extractedParams[i],
                        isUsed: false  // Will be marked as used if referenced in body
                    });
                }
            } else {
                // Fall back to wildcard if no name provided
                args.push(PWildcard);
            }
        }

        // Create tuple pattern {:tag, param1, param2, ...}
        return PTuple([PLiteral(makeAST(EAtom(tag)))].concat(args));
    }
    
    /**
     * Convert enum field with extraction support
     */
    private static function convertEnumFieldWithExtraction(ef: EnumField, extractedParams: Array<String>, 
                                                          enumType: EnumType, context: BuildContext): EPattern {
        // Direct enum constructor reference
        var atomName = ef.name.toSnakeCase();
        
        // Extract parameter count from the enum field's type
        var paramCount = 0;
        switch(ef.type) {
            case TFun(args, _):
                paramCount = args.length;
            default:
                // No parameters
        }
        
        if (paramCount == 0) {
            // No-argument constructor
            return PLiteral(makeAST(EAtom(atomName)));
        } else {
            // Constructor with arguments - use extracted param names
            var patterns = [PLiteral(makeAST(EAtom(atomName)))];
            for (i in 0...paramCount) {
                if (i < extractedParams.length && extractedParams[i] != null) {
                    patterns.push(PVar(extractedParams[i]));
                } else {
                    patterns.push(PWildcard);
                }
            }
            return PTuple(patterns);
        }
    }
    
    /**
     * Apply underscore prefix to unused pattern variables
     *
     * WHY: In Elixir, unused variables should be prefixed with underscore to avoid warnings
     * WHAT: DISABLED - This logic is now handled by UsageAnalysis pass in HygieneTransforms
     * HOW: Returns pattern unchanged; UsageAnalysis determines actual usage with complete AST
     *
     * HISTORICAL NOTE: Previously tried to add underscore prefixes during AST building,
     * but this was premature - we don't have enough information at build time to know
     * if a variable is truly unused. The UsageAnalysis pass has the complete AST and
     * can accurately determine usage.
     *
     * @param isEmptyBody IGNORED - kept for API compatibility
     */
    public static function applyUnderscorePrefixToUnusedPatternVars(pattern: EPattern, variableUsageMap: Map<Int, Bool>,
                                                                   extractedParams: Array<String>,
                                                                   isEmptyBody: Bool = false): EPattern {
        // NO-OP: Return pattern unchanged
        // UsageAnalysis pass will handle underscore prefixing with proper usage information
        return pattern;
    }
    
    /**
     * Compute a key string for a pattern (for deduplication/caching)
     */
    public static function computePatternKey(pattern: EPattern): String {
        return switch(pattern) {
            case PVar(name): "var:" + name;
            case PWildcard: "_";
            case PLiteral(ast): 
                switch(ast.def) {
                    case EInteger(i): "int:" + i;
                    case EFloat(f): "float:" + f;
                    case EString(s): "string:" + s;
                    case EBoolean(b): "bool:" + b;
                    case EAtom(a): "atom:" + a;
                    case ENil: "nil";
                    case _: "literal";
                }
            case PTuple(elements):
                "tuple:" + elements.length;
            case PList(_): "list";
            case PCons(_, _): "cons";
            case PMap(_): "map";
            case PStruct(_, _): "struct";
            case PPin(_): "pin";
            case PAlias(_, _): "alias";
            case PBinary(_): "binary";
            default: "unknown";
        };
    }
    
    /**
     * Extract bound variables from a pattern
     */
    public static function extractBoundVariables(pattern: EPattern): Array<String> {
        var vars = [];
        
        function extractFromPattern(p: EPattern): Void {
            switch(p) {
                case PVar(name):
                    if (name.charAt(0) != "_") {
                        vars.push(name);
                    }
                case PTuple(elements):
                    for (elem in elements) {
                        extractFromPattern(elem);
                    }
                case PList(elements):
                    for (elem in elements) {
                        extractFromPattern(elem);
                    }
                case PCons(head, tail):
                    extractFromPattern(head);
                    extractFromPattern(tail);
                case PAlias(varName, p):
                    vars.push(varName);
                    extractFromPattern(p);
                default:
                    // Other patterns don't bind variables
            }
        }
        
        extractFromPattern(pattern);
        return vars;
    }
    
    // ================================================================
    // Utility Functions (moved from ElixirASTBuilder)
    // ================================================================
    
    /**
     * Extract pattern from left-hand side expression
     */
    public static function extractPattern(expr: TypedExpr): EPattern {
        return switch(expr.expr) {
            case TLocal(v): PVar(ElixirASTHelpers.toElixirVarName(v.name));
            case TField(e, fa): 
                // Map/struct field pattern
                PVar(extractFieldName(fa));
            default: PWildcard;
        }
    }
    
    /**
     * Check if a pattern variable is used in the case body
     * 
     * WHY: Elixir compiler warns about unused pattern variables. We need to detect truly unused
     *      variables to prefix them with underscore, avoiding compiler warnings.
     */
    public static function isPatternVariableUsed(varName: String, caseBody: TypedExpr): Bool {
        // Build alias sets to track temp variable relationships
        var aliasMap: Map<String, Array<String>> = new Map();
        var tempsByIndex: Map<Int, String> = new Map();
        var isUsed = false;

        // First pass: collect aliases and temp variable relationships
        function collectAliases(expr: TypedExpr): Void {
            switch(expr.expr) {
                case TVar(v, init) if (init != null):
                    var vName = ElixirASTHelpers.toElixirVarName(v.name);

                    switch(init.expr) {
                        case TEnumParameter(_, _, index):
                            // This is: tempVar = elem(enum, index)
                            // Record that this temp variable extracts from this index
                            tempsByIndex.set(index, vName);

                            // Initialize alias set for this temp
                            if (!aliasMap.exists(vName)) {
                                aliasMap.set(vName, [vName]);
                            }

                        case TLocal(sourceVar):
                            // This is: destVar = sourceVar (simple assignment)
                            var sourceName = ElixirASTHelpers.toElixirVarName(sourceVar.name);

                            // If source has an alias set, add dest to it
                            if (aliasMap.exists(sourceName)) {
                                var aliases = aliasMap.get(sourceName);
                                if (aliases.indexOf(vName) == -1) {
                                    aliases.push(vName);
                                }
                                // Also give dest its own entry pointing to same array
                                aliasMap.set(vName, aliases);
                            } else {
                                // Create new alias set for both
                                var aliases = [sourceName, vName];
                                aliasMap.set(sourceName, aliases);
                                aliasMap.set(vName, aliases);
                            }

                        default:
                            // Other init types don't create aliases
                    }

                default:
                    // Recursively collect from sub-expressions
                    haxe.macro.TypedExprTools.iter(expr, collectAliases);
            }
        }

        // Collect all aliases in the case body
        if (caseBody != null) {
            collectAliases(caseBody);
        }

        // Build complete alias set for our pattern variable
        var aliasesToCheck = [varName];

        // Add any directly mapped aliases
        if (aliasMap.exists(varName)) {
            aliasesToCheck = aliasMap.get(varName).copy();
        }

        // Also check temp variables that might represent this pattern variable
        // Pattern variables like "code", "msg" often become "g", "g1", etc.
        // If varName matches pattern like g, g1, g2, include it
        if (varName == "g" || (varName.length > 1 && varName.charAt(0) == "g" &&
            varName.charAt(1) >= '0' && varName.charAt(1) <= '9')) {
            // This IS a temp variable, check if pattern var maps to it
            for (alias in aliasMap.keys()) {
                var aliases = aliasMap.get(alias);
                if (aliases.indexOf(varName) != -1 && aliasesToCheck.indexOf(alias) == -1) {
                    aliasesToCheck.push(alias);
                }
            }
        } else {
            // This is a pattern variable, check if any temps map to it
            for (tempName in tempsByIndex) {
                if (aliasMap.exists(tempName)) {
                    var aliases = aliasMap.get(tempName);
                    if (aliases.indexOf(varName) != -1) {
                        // This temp is an alias of our pattern var
                        for (a in aliases) {
                            if (aliasesToCheck.indexOf(a) == -1) {
                                aliasesToCheck.push(a);
                            }
                        }
                    }
                }
            }
        }

        // Second pass: check if any alias is actually used (not just declared)
        function checkUsage(expr: TypedExpr): Void {
            if (isUsed) return; // Early exit if already found

            switch(expr.expr) {
                case TLocal(v):
                    var vName = ElixirASTHelpers.toElixirVarName(v.name);
                    // Check if this local reference is any of our aliases
                    if (aliasesToCheck.indexOf(vName) != -1) {
                        isUsed = true;
                    }

                case TVar(v, _):
                    // Variable declaration is NOT usage
                    // But still recurse into the init expression if present

                default:
                    // Recursively check sub-expressions
                    haxe.macro.TypedExprTools.iter(expr, checkUsage);
            }
        }

        if (caseBody != null) {
            checkUsage(caseBody);
        }

        return isUsed;
    }
    
    /**
     * Check if a pattern variable is used in the case body using variable IDs
     */
    public static function isPatternVariableUsedById(varId: Int, caseBody: TypedExpr, ?varOriginMap: Map<Int, ElixirAST.VarOrigin>): Bool {
        // Build set of used variable IDs in case body
        var usedVarIds = new Map<Int, Bool>();

        function collectUsedVarIds(expr: TypedExpr): Void {
            switch(expr.expr) {
                case TLocal(v):
                    // This is a usage of a variable
                    usedVarIds.set(v.id, true);

                case TVar(v, _):
                    // Variable declaration is NOT usage
                    // The variable ID v.id is being declared, not used
                    // But recurse into init expression if present

                default:
                    // Recursively check sub-expressions
            }

            // Always recurse into sub-expressions
            haxe.macro.TypedExprTools.iter(expr, collectUsedVarIds);
        }

        // Collect all used variable IDs
        if (caseBody != null) {
            collectUsedVarIds(caseBody);
        }

        // Check if our variable ID is in the used set
        return usedVarIds.exists(varId);
    }
    
    /**
     * Check if a case body is effectively empty (only nil or no-op)
     */
    public static function isEmptyCaseBody(body: ElixirAST): Bool {
        if (body == null) return true;
        
        return switch(body.def) {
            case EAtom(a): a == "nil";
            case ENil: true;
            case EBlock(exprs): 
                exprs.length == 0 || 
                (exprs.length == 1 && isEmptyCaseBody(exprs[0]));
            default: false;
        };
    }
    
    /**
     * Update ClauseContext mapping to account for underscore-prefixed variables
     *
     * WHY: When a pattern variable gets prefixed with underscore (e.g., code -> _code),
     *      the ClauseContext mapping needs to be updated so the case body can still
     *      reference the correct variable
     * WHAT: Scans the pattern for underscore-prefixed variables and updates the mapping
     * HOW: Walks through the pattern and updates mappings for any PVar with underscore prefix
     */
    public static function updateMappingForUnderscorePrefixes(pattern: EPattern, originalMapping: Map<Int, String>, extractedParams: Array<String>): Map<Int, String> {
        var needsUpdate = false;
        var newMapping = new Map<Int, String>();

        // First, copy the original mapping
        for (id => name in originalMapping) {
            newMapping.set(id, name);
        }

        // Check if any pattern variables have underscore prefixes
        function checkPattern(p: EPattern, index: Int = 0): Void {
            switch(p) {
                case PTuple(patterns):
                    for (i in 0...patterns.length) {
                        checkPattern(patterns[i], i);
                    }
                case PVar(name) if (name.charAt(0) == "_" && name.length > 1):
                    // This variable has an underscore prefix
                    // Update any mapping that pointed to the non-prefixed version
                    var originalName = name.substring(1); // Remove underscore
                    for (id => mappedName in originalMapping) {
                        if (mappedName == originalName) {
                            // Update this mapping to use the prefixed name
                            newMapping.set(id, name);
                            needsUpdate = true;
                        }
                    }
                default:
                    // Other patterns don't need updates
            }
        }

        checkPattern(pattern);

        return needsUpdate ? newMapping : originalMapping;
    }
    
    // ================================================================
    // Private Helper Functions
    // ================================================================
    
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
     * Extract enum tag from TypedExpr
     */
    static function extractEnumTag(expr: TypedExpr): String {
        return switch(expr.expr) {
            case TField(_, FEnum(_, ef)): ef.name;
            default: "unknown";
        };
    }
    
    /**
     * Check if expression has idiomatic metadata
     */
    static function hasIdiomaticMetadata(expr: TypedExpr): Bool {
        // Check if this is an idiomatic enum
        switch(expr.expr) {
            case TField(_, FEnum(enumRef, _)):
                return enumRef.get().meta.has("elixirIdiomatic") || true; // All enums idiomatic now
            default:
                return false;
        }
    }
    
    /**
     * Helper to create AST nodes
     */
    private static function makeAST(def: ElixirASTDef): ElixirAST {
        return {
            def: def,
            pos: null,
            metadata: {}
        };
    }
}

// ================================================================
// Type Definitions
// ================================================================


/**
 * Enum binding plan for pattern compilation
 */
typedef EnumBindingPlan = {
    var enumConstructor: String;
    var parameterBindings: Array<ParameterBinding>;
    var isIdiomatic: Bool;
    /** Parameters extracted by the pattern itself (for coordination with body compilation) */
    var patternExtractedParams: Array<String>;
}

/**
 * Parameter binding information
 */
typedef ParameterBinding = {
    var index: Int;
    var name: String;
    var isUsed: Bool;
}

#end
