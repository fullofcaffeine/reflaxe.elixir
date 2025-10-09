package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTHelpers;
import reflaxe.elixir.ast.context.BuildContext;
import reflaxe.elixir.helpers.PatternDetector;
using reflaxe.elixir.ast.NameUtils;
using StringTools;

/**
 * EnumHandler: Enum Pattern Matching and Code Generation
 * 
 * WHY: Centralizes all enum-related transformations for Haxe→Elixir compilation
 * - Handles conversion of Haxe enums to Elixir tagged tuples
 * - Manages idiomatic pattern generation (e.g., {:ok, value})
 * - Extracts and tracks enum parameters in pattern matching
 * - Generates Enum module operations (map, filter, reduce)
 * 
 * WHAT: Core enum handling capabilities
 * - Enum constructor detection and analysis
 * - Pattern generation for case expressions
 * - Parameter extraction and binding plans
 * - Idiomatic vs regular enum patterns
 * - Enum operation generation (Enum.map, Enum.filter, etc.)
 * 
 * HOW: Pattern analysis and AST transformation
 * - Analyzes TypedExpr to detect enum usage
 * - Creates binding plans for parameter extraction
 * - Generates appropriate patterns based on metadata
 * - Transforms enum operations to idiomatic Elixir
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: All enum logic in one place
 * - Open/Closed: Easy to extend enum handling
 * - Testability: Isolated enum transformation logic
 * - Maintainability: Clear separation from other concerns
 * - Performance: Optimized enum pattern detection
 * 
 * EDGE CASES:
 * - Nested enum patterns
 * - Unused enum parameters (underscore prefixing)
 * - Idiomatic enums (Option, Result) vs custom enums
 * - Complex parameter extraction in case expressions
 * - Multiple enum constructors in same pattern
 */
@:nullSafety(Off)
class EnumHandler {
    
    // ================================================================
    // Enum Detection
    // ================================================================
    
    /**
     * Check if an expression is an enum constructor
     * 
     * WHY: Need to identify enum constructors for special handling
     * WHAT: Detects TCall to enum field references
     * HOW: Pattern matches on TypedExpr structure
     */
    public static function isEnumConstructor(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch(expr.expr) {
            case TField(e, FEnum(_, ef)):
                return true;
            case TCall(e, _):
                return isEnumConstructor(e);
            case _:
                return false;
        }
    }
    
    /**
     * Extract the tag name from an enum constructor
     * 
     * WHY: Need constructor name for pattern matching
     * WHAT: Extracts the enum field name
     * HOW: Traverses expression to find enum field
     */
    public static function extractEnumTag(expr: TypedExpr): String {
        switch(expr.expr) {
            case TField(_, FEnum(_, ef)):
                return ef.name;
            case TCall(e, _):
                return extractEnumTag(e);
            case _:
                return "";
        }
    }
    
    /**
     * Get the enum type name from an expression
     * 
     * WHY: Need to identify which enum type is being used
     * WHAT: Extracts the enum type name
     * HOW: Pattern matches to find enum reference
     */
    public static function getEnumTypeName(expr: TypedExpr): String {
        switch(expr.expr) {
            case TField(_, FEnum(enumRef, _)):
                return enumRef.get().name;
            case TCall(e, _):
                return getEnumTypeName(e);
            case _:
                return "";
        }
    }
    
    // ================================================================
    // Enum Operations Generation
    // ================================================================
    
    /**
     * Generate Enum.map operation from array and transformation
     * 
     * WHY: Transform imperative loops to functional Enum operations
     * WHAT: Creates Enum.map call with lambda
     * HOW: Builds AST for functional transformation
     */
    public static function generateEnumMap(arrayExpr: ElixirAST, itemVar: String, transformation: ElixirAST, context: BuildContext): ElixirAST {
        var lambda = makeAST(EFn([{
            args: [PVar(itemVar)],
            guard: null,
            body: transformation
        }]));
        
        return makeAST(ECall(null, "Enum.map", [arrayExpr, lambda]));
    }
    
    /**
     * Generate Enum.filter operation
     * 
     * WHY: Transform imperative filtering to functional style
     * WHAT: Creates Enum.filter call with predicate lambda
     * HOW: Builds AST for functional filter
     */
    public static function generateEnumFilter(arrayExpr: ElixirAST, itemVar: String, condition: ElixirAST, context: BuildContext): ElixirAST {
        var lambda = makeAST(EFn([{
            args: [PVar(itemVar)],
            guard: null,
            body: condition
        }]));
        
        return makeAST(ECall(null, "Enum.filter", [arrayExpr, lambda]));
    }
    
    /**
     * Generate Enum.reduce operation
     * 
     * WHY: Transform imperative accumulation to functional reduce
     * WHAT: Creates Enum.reduce call with accumulator lambda
     * HOW: Builds AST for functional reduction
     */
    public static function generateEnumReduce(arrayExpr: ElixirAST, itemVar: String, accVar: String, 
                                             initialValue: ElixirAST, body: ElixirAST, context: BuildContext): ElixirAST {
        var lambda = makeAST(EFn([{
            args: [PVar(itemVar), PVar(accVar)],
            guard: null,
            body: body
        }]));
        
        return makeAST(ECall(null, "Enum.reduce", [arrayExpr, initialValue, lambda]));
    }
    
    // ================================================================
    // Parameter Extraction and Analysis
    // ================================================================
    
    /**
     * Analyze enum parameter extraction in case expressions
     * 
     * WHY: Need to track which parameters are extracted and used
     * WHAT: Analyzes TEnumParameter nodes in case body
     * HOW: Recursively traverses expression tree
     * 
     * @param caseExpr The case expression body to analyze
     * @param caseValues Optional specific case values to consider
     * @return Array of extracted parameter variable names
     */
    public static function analyzeEnumParameterExtraction(caseExpr: TypedExpr, caseValues: Array<TypedExpr> = null): Array<String> {
        var extractedParams = [];
        var seenVars = new Map<String, Bool>();
        
        function analyze(expr: TypedExpr) {
            if (expr == null) return;
            
            switch(expr.expr) {
                case TVar(v, init):
                    if (init != null) {
                        switch(init.expr) {
                            case TEnumParameter(_, _, _):
                                var varName = v.name;
                                if (!seenVars.exists(varName)) {
                                    extractedParams.push(varName);
                                    seenVars.set(varName, true);
                                }
                            case _:
                                analyze(init);
                        }
                    }
                
                case TEnumParameter(_, _, _):
                    // Direct usage without assignment
                    
                case TBlock(exprs):
                    for (e in exprs) {
                        analyze(e);
                    }
                
                default:
                    TypedExprTools.iter(expr, analyze);
            }
        }
        
        analyze(caseExpr);
        return extractedParams;
    }
    
    /**
     * Create binding plan for enum parameters
     * 
     * WHY: Need to coordinate parameter names across pattern and body
     * WHAT: Creates mapping of parameter indices to variable names
     * HOW: Analyzes extracted parameters and usage patterns
     * 
     * @param caseExpr The case expression to analyze
     * @param extractedParams Parameter names from extraction analysis
     * @param enumType The enum type information
     * @return Binding plan with final names and usage flags
     */
    public static function createEnumBindingPlan(caseExpr: TypedExpr, extractedParams: Array<String>, 
                                                 enumType: Null<EnumType>, context: BuildContext): {
        plan: Map<Int, {finalName: String, isUsed: Bool}>,
        paramIndexToVarId: Map<Int, Int>
    } {
        var plan = new Map<Int, {finalName: String, isUsed: Bool}>();
        var paramIndexToVarId = new Map<Int, Int>();
        
        // Simple implementation for now
        for (i in 0...extractedParams.length) {
            plan.set(i, {
                finalName: extractedParams[i],
                isUsed: true // Would need proper usage analysis
            });
        }
        
        return {
            plan: plan,
            paramIndexToVarId: paramIndexToVarId
        };
    }
    
    // ================================================================
    // Pattern Generation
    // ================================================================
    
    /**
     * Convert enum to idiomatic pattern (e.g., {:ok, value})
     * 
     * WHY: Generate Elixir-idiomatic patterns for common enums
     * WHAT: Creates atom-based tuple patterns
     * HOW: Converts constructor name to snake_case atom
     * 
     * @param value The enum expression
     * @param enumType The enum type information
     * @param extractedParams Parameters to extract
     * @param context Build context with usage information
     * @return Generated pattern
     */
    public static function convertIdiomaticEnumPattern(value: TypedExpr, enumType: EnumType, 
                                                       extractedParams: Array<String>, context: BuildContext): EPattern {
        var tag = extractEnumTag(value);
        if (tag == "") return PWildcard;
        
        // Convert to snake_case for idiomatic Elixir
        var atomName = tag.toSnakeCase();
        
        // Get constructor parameters
        var params = [];
        switch(value.expr) {
            case TCall(_, el):
                for (i in 0...el.length) {
                    if (i < extractedParams.length) {
                        params.push(PVar(extractedParams[i]));
                    } else {
                        params.push(PWildcard);
                    }
                }
            case _:
        }
        
        // Build tuple pattern; preserve {:tag} even for zero-arg constructors
        if (params.length > 0) {
            var tupleElements = [PLiteral(makeAST(EAtom(atomName)))].concat(params);
            return PTuple(tupleElements);
        } else {
            return PTuple([PLiteral(makeAST(EAtom(atomName)))]);
        }
    }
    
    /**
     * Convert enum to regular pattern (module-based)
     * 
     * WHY: Handle custom enums that don't use idiomatic patterns
     * WHAT: Creates module-qualified patterns
     * HOW: Uses enum type name and constructor
     * 
     * @param value The enum expression
     * @param enumType The enum type information
     * @param extractedParams Parameters to extract
     * @param context Build context
     * @return Generated pattern
     */
    public static function convertRegularEnumPattern(value: TypedExpr, enumType: EnumType,
                                                     extractedParams: Array<String>, context: BuildContext): EPattern {
        var tag = extractEnumTag(value);
        if (tag == "") return PWildcard;
        
        var typeName = enumType.name;
        var params = [];
        
        switch(value.expr) {
            case TCall(_, el):
                for (i in 0...el.length) {
                    if (i < extractedParams.length) {
                        params.push(PVar(extractedParams[i]));
                    } else {
                        params.push(PWildcard);
                    }
                }
            case _:
        }
        
        // Build module-qualified pattern
        // For now, use tuple pattern with atom tag
        // TODO: Implement proper module-qualified patterns
        var atomPattern = PLiteral(makeAST(EAtom(tag.toSnakeCase())));
        if (params.length > 0) {
            return PTuple([atomPattern].concat(params));
        } else {
            return PTuple([atomPattern]);
        }
    }
    
    // ================================================================
    // Usage Analysis
    // ================================================================
    
    /**
     * Check if enum parameter at index is used in body
     * 
     * WHY: Determine if parameter needs underscore prefix
     * WHAT: Analyzes usage of specific parameter index
     * HOW: Traverses body looking for TEnumParameter references
     * 
     * @param index Parameter index to check
     * @param caseBody Expression body to analyze
     * @return True if parameter is used
     */
    public static function isEnumParameterUsedAtIndex(index: Int, caseBody: TypedExpr): Bool {
        var isUsed = false;

        /**
         * Traverse with context awareness to distinguish extraction from usage.
         * inExtractionContext = true when descending into TVar init of a pattern-extracted binding.
         */
        function checkUsage(expr: TypedExpr, inExtractionContext: Bool): Void {
            if (isUsed || expr == null) return;

            switch(expr.expr) {
                case TEnumParameter(_, _, paramIndex):
                    // Count only when NOT inside extraction (e.g., directly used in expressions)
                    if (!inExtractionContext && paramIndex == index) {
                        isUsed = true;
                    }

                case TVar(v, init) if (init != null):
                    // If this TVar binds from the enum parameter, treat as extraction only;
                    // we only mark used if the bound variable is referenced elsewhere.
                    switch(init.expr) {
                        case TEnumParameter(_, _, paramIndex) if (paramIndex == index):
                            var varName = v.name;
                            if (isVariableUsedInExpression(varName, caseBody)) {
                                isUsed = true;
                            }
                        case _:
                            // Explore init normally but mark as extraction context to avoid false positives
                            checkUsage(init, true);
                    }

                default:
                    // Recurse into children preserving the current context
                    TypedExprTools.iter(expr, function(e) checkUsage(e, inExtractionContext));
            }
        }

        checkUsage(caseBody, false);
        return isUsed;
    }

    /**
     * Check if a variable name is referenced (as TLocal) within a case body.
     * This ignores mere extraction bindings (TVar) and only counts true usages.
     */
    public static function isVariableNameUsedInBody(varName: String, caseBody: TypedExpr): Bool {
        var used = false;
        inline function baseName(s:String):String {
            var re = ~/([0-9]+)$/;
            return re.replace(s, "");
        }
        var baseVar = baseName(varName);
        function check(e: TypedExpr): Void {
            if (used || e == null) return;
            switch (e.expr) {
                case TLocal(v):
                    var name = v.name;
                    var base = baseName(name);
                    if (name == varName || base == baseVar) {
                        used = true;
                    } else {
                        TypedExprTools.iter(e, check);
                    }
                case TVar(_, _):
                    // Declarations do not count as usage
                default:
                    TypedExprTools.iter(e, check);
            }
        }
        check(caseBody);
        return used;
    }
    
    /**
     * Helper to check if a variable is used in an expression
     */
    static function isVariableUsedInExpression(varName: String, expr: TypedExpr): Bool {
        var used = false;
        inline function baseName(s:String):String {
            var re = ~/([0-9]+)$/;
            return re.replace(s, "");
        }
        var baseVar = baseName(varName);
        function check(e: TypedExpr): Void {
            if (used) return;
            switch(e.expr) {
                case TLocal(v):
                    var name = v.name;
                    var base = baseName(name);
                    if (name == varName || base == baseVar) {
                        used = true;
                    } else {
                        TypedExprTools.iter(e, check);
                    }
                default:
                    TypedExprTools.iter(e, check);
            }
        }
        check(expr);
        return used;
    }
    
    // ================================================================
    // Case Body Processing
    // ================================================================
    
    /**
     * Process enum case body for special handling
     * 
     * WHY: Some enum cases need special transformations
     * WHAT: Applies enum-specific transformations to case body
     * HOW: Analyzes and modifies AST based on enum patterns
     * 
     * @param caseExpr Original case expression
     * @param builtBody Built AST body
     * @return Processed body
     */
    public static function processEnumCaseBody(caseExpr: TypedExpr, builtBody: ElixirAST): ElixirAST {
        // Check for specific patterns that need transformation
        switch(caseExpr.expr) {
            case TBlock(exprs) if (exprs.length == 1):
                switch(exprs[0].expr) {
                    case TEnumParameter(_, _, _):
                        // Single enum parameter extraction
                        return builtBody;
                    case _:
                }
            case _:
        }
        
        return builtBody;
    }
}

#end
