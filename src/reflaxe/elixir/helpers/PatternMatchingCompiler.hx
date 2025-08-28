package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.helpers.NamingHelper;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * Function context information for field assignment transformations
 */
typedef FunctionContext = {
    structParamName: Null<String>  // Name of the struct parameter (e.g., "struct", "this", etc.)
};

/**
 * Pattern Matching Compiler for Reflaxe.Elixir
 * 
 * WHY: Elixir's pattern matching is fundamentally different from Haxe's switch statements.
 * This compiler handles the transformation from Haxe's imperative switch/case to Elixir's 
 * functional pattern matching, including:
 * - case/cond/with statement generation
 * - Enum pattern destructuring  
 * - Option/Result type patterns
 * - Guard clause generation
 * - Pattern variable extraction
 * 
 * WHAT: Provides comprehensive pattern matching compilation including:
 * - Switch expression to case/cond/with transformation
 * - Enum constructor pattern generation
 * - Special handling for Option<T> and Result<T,E> types
 * - Pattern argument compilation with proper destructuring
 * - Guard clause support for complex conditions
 * 
 * HOW: The compiler analyzes switch expressions and transforms them based on:
 * 1. Pattern complexity (simple values vs enum constructors)
 * 2. Special type handling (Option, Result, custom enums)
 * 3. Guard requirements (when conditions are needed)
 * 4. Expression vs statement context (return value handling)
 * 
 * @see documentation/PATTERN_MATCHING.md - Complete pattern matching documentation
 */
@:nullSafety(Off)
class PatternMatchingCompiler {
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    
    /**
     * Track whether the current switch is based on elem() call
     * This helps determine if patterns should be integers or tuples
     */
    private var currentSwitchIsElemBased: Bool = false;
    
    /**
     * CRITICAL FIX: Track enum pattern nesting level to prevent variable collision
     * 
     * WHY: When enum switches are nested, the same g_array variable name is reused,
     * causing variable shadowing and potential runtime bugs.
     * 
     * WHAT: Counter that increments with each nested enum switch to generate
     * unique variable names (g_array, g_array2, g_array3, etc.)
     * 
     * HOW: Incremented before compiling nested switches, decremented after completion.
     * Used to generate unique parameter extraction variable names.
     */
    private var enumNestingLevel: Int = 0;
    
    /**
     * Create a new pattern matching compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Compile a switch expression to Elixir pattern matching
     * 
     * WHY: Haxe switch statements need transformation to idiomatic Elixir case/cond/with
     * 
     * WHAT: Analyzes switch patterns and generates appropriate Elixir construct:
     * - Simple value matching → case statement
     * - Complex conditions → cond statement  
     * - Pattern destructuring → with statement
     * 
     * HOW:
     * 1. Analyze switch expression type and patterns
     * 2. Determine if enum/special type handling needed
     * 3. Check for with statement optimization
     * 4. Generate appropriate Elixir pattern matching
     * 
     * @param switchExpr The expression being switched on
     * @param cases Array of case patterns and expressions
     * @param defaultExpr Optional default case expression
     * @return Generated Elixir pattern matching code
     */
    public function compileSwitchExpression(
        switchExpr: TypedExpr, 
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, 
        defaultExpr: Null<TypedExpr>,
        ?context: FunctionContext
    ): String {
        
        // CRITICAL FIX: Track nesting level to prevent enum pattern variable collisions
        enumNestingLevel++;
        // trace('[XRay PatternMatchingCompiler] Entering nested switch, level: ${enumNestingLevel}');
        
        // CRITICAL FIX: Detect and transform temp variable pattern
        // When Haxe generates switch expressions for return values,
        // it creates a pattern like:
        //   temp_result = nil
        //   switch(expr) {
        //     case A: temp_result = "value1"
        //     case B: temp_result = "value2"
        //   }
        //   return temp_result
        // We need to transform this to direct value returns
        
        var tempVarName: String = null;
        var allCasesAssignToTempVar = true;
        
        // CRITICAL DEBUG: Track switch compilation
        // Sys.println('[SWITCH_TRACKER] ===== SWITCH COMPILATION START =====');
        // Sys.println('[SWITCH_TRACKER] Switch expr type: ${Type.enumConstructor(switchExpr.expr)}');  
        // Sys.println('[SWITCH_TRACKER] Number of cases: ${cases.length}');
        
        #if debug_temp_var
//         trace("[PatternMatchingCompiler] ============== SWITCH COMPILATION START ==============");
//         trace('[PatternMatchingCompiler] compileSwitchExpression called');
//         trace('[PatternMatchingCompiler] Switch expr type: ${switchExpr.expr}');
//         trace('[PatternMatchingCompiler] Switch expr t type: ${switchExpr.t}');
//         trace('[PatternMatchingCompiler] Number of cases: ${cases.length}');
//         trace('[PatternMatchingCompiler] Has default: ${defaultExpr != null}');
        #end
        
        // Check for temp variable assignment patterns in all cases
        for (i in 0...cases.length) {
            var caseData = cases[i];
            
            #if debug_temp_var
//             trace('[PatternMatchingCompiler] Case ${i}: ${caseData.values.length} values');
            for (v in caseData.values) {
//                 trace('[PatternMatchingCompiler]   Value: ${v.expr}');
            }
            #end
            
            // Check case body for temp variable patterns
            switch (caseData.expr.expr) {
                case TBinop(OpAssign, left, right):
                    switch (left.expr) {
                        case TLocal(v):
                            var varName = compiler.getOriginalVarName(v);
                            #if debug_temp_var
//                             trace('[PatternMatchingCompiler]   Case body assigns to: ${varName}');
                            #end
                            
                            if (varName.indexOf("temp") == 0) {
                                if (tempVarName == null) {
                                    tempVarName = varName;
                                    #if debug_temp_var
//                                     trace('[PatternMatchingCompiler]   ✓ TEMP VARIABLE ASSIGNMENT DETECTED: ${tempVarName}');
                                    #end
                                } else if (tempVarName != varName) {
                                    // Different temp variables in different cases
                                    allCasesAssignToTempVar = false;
                                }
                            } else {
                                allCasesAssignToTempVar = false;
                            }
                        case _:
                            allCasesAssignToTempVar = false;
                            #if debug_temp_var
//                             trace('[PatternMatchingCompiler]   Case body assigns to non-local');
                            #end
                    }
                case _:
                    allCasesAssignToTempVar = false;
                    #if debug_temp_var
//                     trace('[PatternMatchingCompiler]   Case body type: ${caseData.expr.expr}');
                    #end
            }
        }
        
        // If all cases assign to the same temp variable, transform them
        if (allCasesAssignToTempVar && tempVarName != null) {
            #if debug_temp_var
//             trace('[PatternMatchingCompiler] ✓ ALL CASES ASSIGN TO TEMP VARIABLE: ${tempVarName}');
//             trace('[PatternMatchingCompiler] Transforming to direct value returns...');
            #end
            
            // Transform case bodies to return values directly
            var transformedCases = [];
            for (caseData in cases) {
                var transformedExpr = switch (caseData.expr.expr) {
                    case TBinop(OpAssign, left, right):
                        // Strip the assignment and return just the value
                        right;
                    case _:
                        // Should not happen if allCasesAssignToTempVar is true
                        caseData.expr;
                };
                
                transformedCases.push({
                    values: caseData.values,
                    expr: transformedExpr
                });
            }
            
            // Transform default expression if it exists and assigns to temp var
            var transformedDefault = if (defaultExpr != null) {
                switch (defaultExpr.expr) {
                    case TBinop(OpAssign, left, right):
                        switch (left.expr) {
                            case TLocal(v):
                                var varName = compiler.getOriginalVarName(v);
                                if (varName == tempVarName) {
                                    right; // Return just the value
                                } else {
                                    defaultExpr;
                                }
                            case _:
                                defaultExpr;
                        }
                    case _:
                        defaultExpr;
                }
            } else {
                null;
            };
            
            // Use transformed cases and default
            cases = transformedCases;
            defaultExpr = transformedDefault;
            
            #if debug_temp_var
//             trace('[PatternMatchingCompiler] ✓ TRANSFORMATION COMPLETE');
            #end
        }
        
        #if debug_temp_var
//         trace("[PatternMatchingCompiler] ============== SWITCH COMPILATION END ==============");
        #end
        
        
        #if debug_pattern_matching
//         trace("[PatternMatchingCompiler] Compiling switch expression");
//         trace('[PatternMatchingCompiler] Switch expr type: ${switchExpr.t}');
//         trace('[PatternMatchingCompiler] Number of cases: ${cases.length}');
        #end
        
        // CRITICAL FIX: Detect TSwitch(TEnumIndex(expr)) pattern for direct Result/Option compilation
        // This prevents double-nested case expressions by bypassing EnumIntrospectionCompiler
        if (isSwitchOnEnumIndex(switchExpr)) {
            // Sys.println('[SWITCH_TRACKER] EARLY RETURN - isSwitchOnEnumIndex');
            #if debug_pattern_matching
//             trace("[PatternMatchingCompiler] ✓ DETECTED TSwitch(TEnumIndex) - direct compilation");
            #end
            enumNestingLevel--;
            return compileSwitchOnEnumIndexDirectly(switchExpr, cases, defaultExpr, context);
        }
        
        // Check if this is a with statement pattern
        if (shouldUseWithStatement(switchExpr, cases)) {
            // Sys.println('[SWITCH_TRACKER] EARLY RETURN - shouldUseWithStatement');
            #if debug_pattern_matching
//             trace("[PatternMatchingCompiler] Using with statement optimization");
            #end
            enumNestingLevel--;
            return compileWithStatement(switchExpr, cases, defaultExpr, context);
        }
        
        // Check for enum type handling
        var enumType = extractEnumType(switchExpr.t);
        
        // Sys.println('[SWITCH_TRACKER] extractEnumType result = ${enumType != null ? enumType.name : "NULL"}');
        
        if (enumType != null) {
            // Sys.println('[SWITCH_TRACKER] ENUM TYPE DETECTED - ${enumType.name}');
            #if debug_pattern_matching
//             trace('[PatternMatchingCompiler] ✓ DETECTED ENUM TYPE: ${enumType.name}');
            #end
            
            // Special handling for Option and Result types
            if (isOptionType(enumType)) {
                #if debug_pattern_matching
//                 trace('[PatternMatchingCompiler] → Using Option switch compilation');
                #end
                enumNestingLevel--;
                return compileOptionSwitch(switchExpr, cases, defaultExpr, context);
            } else if (isResultType(enumType)) {
                #if debug_pattern_matching
//                 trace('[PatternMatchingCompiler] → Using Result switch compilation');
                #end
                enumNestingLevel--;
                return compileResultSwitch(switchExpr, cases, defaultExpr, context);
            } else {
                // CRITICAL FIX: Handle all other enum types with index-based matching
                // Convert switch(enum) to case(elem(enum, 0)) with integer patterns
                #if debug_pattern_matching
//                 trace('[PatternMatchingCompiler] → USING INDEX-BASED MATCHING FOR ENUM: ${enumType.name}');
//                 trace('[PatternMatchingCompiler] → Calling compileEnumIndexSwitch...');
                #end
                enumNestingLevel--;
                return compileEnumIndexSwitch(switchExpr, cases, defaultExpr, context, enumType);
            }
        } else {
            // Sys.println('[SWITCH_TRACKER] NO ENUM TYPE - trying inference');
            #if debug_pattern_matching
//             trace('[PatternMatchingCompiler] ⚠️ NO ENUM TYPE DETECTED - using standard case compilation');
            #end
            
            // CRITICAL FIX: Try to detect enum type from switch cases themselves
            // Sometimes enum type isn't detected from switch expr but we can detect it from patterns
            var inferredEnumType = inferEnumTypeFromCases(cases);
            if (inferredEnumType != null) {
                // Sys.println('[SWITCH_TRACKER] INFERRED ENUM TYPE - ${inferredEnumType.name}');
                #if debug_pattern_matching
//                 trace('[PatternMatchingCompiler] ✓ INFERRED ENUM TYPE: ${inferredEnumType.name} - forcing elem-based compilation');
                #end
                enumNestingLevel--;
                return compileEnumIndexSwitch(switchExpr, cases, defaultExpr, context, inferredEnumType);
            }
            
            // Sys.println('[SWITCH_TRACKER] FORCING ELEM-BASED COMPILATION');
            // CRITICAL FIX: Force ALL switches to use elem-based compilation by default
            // This ensures consistent pattern generation across all enum switches
            #if debug_pattern_matching
//             trace('[PatternMatchingCompiler] ✓ FORCING ALL SWITCHES TO USE ELEM-BASED COMPILATION');
            #end
            enumNestingLevel--;
            return compileEnumIndexSwitch(switchExpr, cases, defaultExpr, context, null);
        }
        
        // Standard case statement compilation
        enumNestingLevel--;
        return compileStandardCase(switchExpr, cases, defaultExpr, context);
    }
    
    /**
     * Compile a with statement for pattern matching with early returns
     * 
     * WHY: Elixir's with statement provides elegant handling of sequential
     * pattern matches with early bailout on failure
     * 
     * @param switchExpr The expression being matched
     * @param cases The pattern cases
     * @param defaultExpr Default/else expression
     * @return Generated with statement
     */
    public function compileWithStatement(
        switchExpr: TypedExpr,
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>,
        defaultExpr: Null<TypedExpr>,
        ?context: FunctionContext
    ): String {
        
        // CRITICAL FIX: Remove 'g' mapping before compiling switch expression
        // The 'g' variable should never be mapped to g_counter in switch expressions
        var savedGMapping: Null<String> = null;
        if (compiler.currentFunctionParameterMap.exists("g")) {
            savedGMapping = compiler.currentFunctionParameterMap.get("g");
            compiler.currentFunctionParameterMap.remove("g");
            #if debug_pattern_matching
//             trace('[PatternMatchingCompiler] Temporarily removed g mapping in with statement: g -> ${savedGMapping}');
            #end
        }
        
        var exprStr = compiler.compileExpression(switchExpr);
        
        // Restore the 'g' mapping after compilation
        // CRITICAL FIX: Don't restore if the mapping is to g_counter - that's always wrong
        if (savedGMapping != null && !StringTools.endsWith(savedGMapping, "_counter")) {
            compiler.currentFunctionParameterMap.set("g", savedGMapping);
        } else if (savedGMapping != null) {
            #if debug_pattern_matching
//             trace('[PatternMatchingCompiler] ⚠️ BLOCKED restoration of incorrect g -> ${savedGMapping} mapping');
            #end
        }
        var patterns: Array<String> = [];
        var elsePatterns: Array<String> = [];
        
        for (caseData in cases) {
            for (value in caseData.values) {
                var pattern = compilePattern(value);
                var body = compilePatternBody(caseData.expr, context);
                
                if (isSuccessPattern(pattern)) {
                    patterns.push('${pattern} <- ${exprStr}');
                } else {
                    elsePatterns.push('${pattern} -> ${body}');
                }
            }
        }
        
        var withBody = patterns.length > 0 ? patterns[patterns.length - 1] : "nil";
        var elseClause = "";
        
        if (elsePatterns.length > 0 || defaultExpr != null) {
            var elseCases = elsePatterns.join("\n    ");
            if (defaultExpr != null) {
                elseCases += '\n    _ -> ${compiler.compileExpression(defaultExpr)}';
            }
            elseClause = '\nelse\n    ${elseCases}\nend';
        }
        
        return 'with ${patterns.join(",\n     ")} do\n  ${withBody}${elseClause}';
    }
    
    /**
     * Compile Result<T,E> pattern matching
     * 
     * WHY: Result types need special handling for idiomatic {:ok, value} | {:error, reason} patterns
     * 
     * @param enumField The Result enum field (Ok or Error)
     * @param args Constructor arguments
     * @return Generated pattern string
     */
    public function compileResultPattern(enumField: EnumField, args: Array<TypedExpr>): String {
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] Compiling Result pattern: ${enumField.name}');
        #end
        
        var patternStr = switch (enumField.name) {
            case "Ok":
                if (args.length > 0) {
                    var valuePattern = compilePatternArgument(args[0]);
                    '{:ok, ${valuePattern}}';
                } else {
                    '{:ok, nil}';
                }
                
            case "Error":
                if (args.length > 0) {
                    var errorPattern = compilePatternArgument(args[0]);
                    '{:error, ${errorPattern}}';
                } else {
                    '{:error, nil}';
                }
                
            default:
                // Fallback for non-standard Result constructors
                compileTuplePattern(enumField.name, args);
        };
        
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] Generated Result pattern: ${patternStr}');
        #end
        
        return patternStr;
    }
    
    /**
     * Compile Option<T> pattern matching
     * 
     * WHY: Option types need special handling for idiomatic {:some, value} | :none patterns
     * 
     * @param enumField The Option enum field (Some or None)
     * @param args Constructor arguments
     * @return Generated pattern string
     */
    public function compileOptionPattern(enumField: EnumField, args: Array<TypedExpr>): String {
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] Compiling Option pattern: ${enumField.name}');
        #end
        
        var patternStr = switch (enumField.name) {
            case "Some":
                if (args.length > 0) {
                    var valuePattern = compilePatternArgument(args[0]);
                    '{:some, ${valuePattern}}';
                } else {
                    '{:some, nil}';
                }
                
            case "None":
                ':none';
                
            default:
                // Fallback for non-standard Option constructors
                compileTuplePattern(enumField.name, args);
        };
        
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] Generated Option pattern: ${patternStr}');
        #end
        
        return patternStr;
    }
    
    /**
     * Compile enum pattern matching
     * 
     * WHY: Enum constructors need transformation to Elixir tuple patterns
     * 
     * @param expr The enum expression
     * @return Generated pattern string
     */
    public function compileEnumPattern(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TCall(e, args):
                switch (e.expr) {
                    case TField(_, FEnum(enumRef, enumField)):
                        var enumType = enumRef.get();
                        
                        // Check for special enum types
                        if (enumType.name == "Option") {
                            compileOptionPattern(enumField, args);
                        } else if (enumType.name == "Result") {
                            compileResultPattern(enumField, args);
                        } else {
                            // CRITICAL FIX: Check if we're in an elem-based switch context
                            if (currentSwitchIsElemBased) {
                                // Generate simple integer pattern for elem-based switches
                                var enumConstructors = [];
                                for (name in enumType.names) {
                                    enumConstructors.push(name);
                                }
                                var constructorIndex = enumConstructors.indexOf(enumField.name);
                                if (constructorIndex >= 0) {
                                    Std.string(constructorIndex);
                                } else {
                                    // Fallback to tuple pattern if index not found
                                    compileTuplePattern(enumField.name, args);
                                }
                            } else {
                                // Standard tuple pattern for non-elem-based switches
                                compileTuplePattern(enumField.name, args);
                            }
                        }
                        
                    default:
                        compiler.compileExpression(expr);
                }
                
            default:
                compiler.compileExpression(expr);
        };
    }
    
    /**
     * Compile pattern matching argument
     * 
     * WHY: Pattern arguments need special handling for variables vs literals
     * 
     * @param expr The argument expression
     * @return Generated pattern string
     */
    public function compilePatternArgument(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TLocal(v):
                // Pattern variable - check if marked as unused by Reflaxe preprocessor
                var isUnused = v.meta != null && v.meta.has("-reflaxe.unused");
                var varName = NamingHelper.toSnakeCase(v.name);
                
                // CRITICAL FIX: Register variable name with VariableCompiler for consistency
                // This ensures nested switch expressions use the same variable name
                var finalName = if (isUnused && !StringTools.startsWith(varName, "_")) {
                    "_" + varName;
                } else {
                    varName;
                }
                
                // Register the final name with VariableCompiler to ensure consistency
                // This prevents mismatches like _parsed_msg vs parsed_msg in nested contexts
                compiler.variableCompiler.registerVariableMapping(v, finalName);
                
                finalName;
                
            case TConst(c):
                // WHY: TConstant vs Constant Type Distinction in Haxe Macro System
                // TypedExpr uses TConstant (from typed AST), not Constant (from untyped AST)
                // These are different enums: TConstant has TInt/TFloat/TString/TBool/TNull/TThis/TSuper
                // while Constant has CInt/CFloat/CString/CIdent/CRegexp - they're incompatible!
                // 
                // WHAT: This was causing OCaml "index out of bounds" errors because Dynamic typing
                // was hiding the type mismatch between TConstant and Constant parameters
                // 
                // HOW: Use LiteralCompiler.compileConstant(TConstant) instead of 
                // ElixirCompiler.compileConstant(Constant) for proper pattern literal generation
                // Examples: TInt(42) → "42", TString("test") → "\"test\"", TBool(true) → "true"
                compiler.expressionDispatcher.literalCompiler.compileConstant(c);
                
            default:
                // Complex pattern
                compiler.compileExpression(expr);
        };
    }
    
    // ================== Private Helper Methods ==================
    
    /**
     * Determine if a with statement should be used
     */
    private function shouldUseWithStatement(
        switchExpr: TypedExpr,
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>
    ): Bool {
        // Check for Result/Option type with early return pattern
        var enumType = extractEnumType(switchExpr.t);
        if (enumType != null && (isResultType(enumType) || isOptionType(enumType))) {
            // Check if cases follow success/failure pattern
            for (caseData in cases) {
                for (value in caseData.values) {
                    if (isSuccessConstructor(value)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    /**
     * Extract enum type from a Type
     */
    private function extractEnumType(type: Type): Null<EnumType> {
        return switch (type) {
            case TEnum(enumRef, _):
                var enumType = enumRef.get();
                enumType;
            case TAbstract(absRef, _):
                // Check if abstract wraps an enum
                null; // TODO: Implement abstract enum extraction
            default:
                null;
        };
    }
    
    /**
     * Check if enum type is Option<T>
     */
    private function isOptionType(enumType: EnumType): Bool {
        return enumType.name == "Option" || 
               enumType.module == "haxe.ds.Option";
    }
    
    /**
     * Check if enum type is Result<T,E>
     */
    private function isResultType(enumType: EnumType): Bool {
        return enumType.name == "Result" || 
               enumType.module == "haxe.functional.Result";
    }
    
    /**
     * Infer enum type from switch cases by analyzing TEnumParameter patterns
     * 
     * WHY: Sometimes the switchExpr doesn't directly reveal the enum type (especially
     * with complex expressions), but we can analyze the case patterns to detect enum usage
     * 
     * WHAT: Examines the case values for TEnumParameter expressions and extracts
     * the enum type from the first detected enum constructor
     * 
     * HOW: Iterates through case values, finds TEnumParameter expressions,
     * and returns the enum type if a consistent pattern is found
     * 
     * @param cases The switch case array to analyze
     * @return The detected enum type, or null if not found
     */
    private function inferEnumTypeFromCases(
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>
    ): Null<EnumType> {
        for (caseData in cases) {
            for (valueExpr in caseData.values) {
                switch (valueExpr.expr) {
                    case TEnumParameter(e, ef, index):
                        // Found an enum parameter - extract the enum type
                        var enumType = extractEnumType(e.t);
                        if (enumType != null) {
                            #if debug_pattern_matching
//                             trace('[inferEnumTypeFromCases] Detected enum type: ${enumType.name}');
//                             trace('[inferEnumTypeFromCases] From constructor: ${ef.name}');
                            #end
                            return enumType;
                        }
                        
                    default:
                        // Continue checking other patterns
                }
            }
        }
        
        #if debug_pattern_matching
//         trace('[inferEnumTypeFromCases] No enum type detected from case patterns');
        #end
        return null;
    }
    
    /**
     * Compile standard case statement
     */
    private function compileStandardCase(
        switchExpr: TypedExpr,
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>,
        defaultExpr: Null<TypedExpr>,
        ?context: FunctionContext
    ): String {
        
        // DEBUG: Track which functions use standard case compilation
        // Sys.println('[CRITICAL_PATH] ===== STANDARD CASE COMPILATION =====');
        // Sys.println('[CRITICAL_PATH] This function is NOT going through enum index compilation');
        // Sys.println('[CRITICAL_PATH] Switch expr: ${Type.enumConstructor(switchExpr.expr)}');
        // Sys.println('[CRITICAL_PATH] Cases: ${cases.length}');
        // Sys.println('[CRITICAL_PATH] ==========================================');
        
        // CRITICAL FIX: Detect if this is an elem() based switch
        // This determines whether patterns should be integers or tuples
        currentSwitchIsElemBased = detectElemBasedSwitch(switchExpr);
        
        
        /**
         * DEFINITIVE FIX FOR G VS G_ARRAY MISMATCH
         * 
         * WHY: When compiling switch(Type.typeof(value)), Haxe creates a TLocal variable
         *      named '_g' or 'g' that gets mapped to 'g_array' via TVar.id mappings.
         *      Previously we were removing this mapping, causing a mismatch where
         *      the assignment used 'g_array' but the case statement used 'g'.
         * 
         * WHAT: Keep the 'g -> g_array' mapping active so both the assignment
         *       and the case statement use the same variable name.
         * 
         * HOW: Simply compile the switch expression with mappings intact.
         *      If it generates 'g_array = expr', extract the variable name
         *      for use in the case statement.
         * 
         * TRADEOFF: This approach respects the TVar.id-based mapping system
         *           that prevents variable collisions, but requires parsing
         *           the compiled expression to extract variable assignments.
         *           The alternative would be to bypass the mapping system
         *           entirely, which would reintroduce collision bugs.
         */
        var compiledExpr = compiler.compileExpression(switchExpr);
        var exprStr = compiledExpr;
        var caseStrings: Array<String> = [];
        
        for (caseData in cases) {
            #if debug_pattern_matching
            // trace("\n[XRay PatternMatchingCompiler] ========== PROCESSING NEW CASE ==========");
            // trace('[XRay PatternMatchingCompiler] Case values count: ${caseData.values.length}');
            for (i in 0...caseData.values.length) {
                // trace('[XRay PatternMatchingCompiler] Case value ${i}: ${caseData.values[i].expr}');
            }
            // trace('[XRay PatternMatchingCompiler] Case body type: ${caseData.expr.expr}');
            #end
            
            // Extract pattern variables from the case body first
            var patternVars = extractPatternVariables(caseData.expr);
            
            #if debug_pattern_matching
            // trace('[XRay PatternMatchingCompiler] Pattern variables extracted: ${Lambda.count(patternVars)} vars');
            for (idx in patternVars.keys()) {
                // trace('[XRay PatternMatchingCompiler]   Index ${idx}: ${patternVars.get(idx)}');
            }
            #end
            
            // Compile patterns with extracted variables
            // Pass the case body for usage detection to properly prefix unused variables
            var patterns = [];
            for (value in caseData.values) {
                patterns.push(compilePatternWithVariables(value, patternVars, caseData.expr));
            }
            
            #if debug_pattern_matching
            // trace('[XRay PatternMatchingCompiler] Generated patterns: ${patterns}');
            #end
            
            // CRITICAL: Clear enum extraction tracking for each case
            // Each case may have different enum patterns with different parameter counts
            compiler.enumExtractionVars = null;
            compiler.currentEnumExtractionIndex = 0;
            
            /**
             * PATTERN USAGE ANALYSIS: Analyze case body to find which variables are actually used
             * 
             * WHY: Need to identify which enum parameters from pattern destructuring are actually
             *      referenced in the case body to prevent orphaned variable generation.
             * 
             * WHAT: Analyze the case body AST to find all TLocal variable references.
             *       Pass this context to EnumIntrospectionCompiler for optimization decisions.
             * 
             * HOW: Use findUsedVariables() to build a map of referenced variable names,
             *      then set compiler.patternUsageContext for EnumIntrospectionCompiler to use.
             */
            var usedVariables = findUsedVariables(caseData.expr);
            compiler.patternUsageContext = usedVariables;
            
            #if debug_pattern_matching
            var usedVarNames = [for (name in usedVariables.keys()) name];
            // trace('[XRay PatternMatchingCompiler] PATTERN USAGE ANALYSIS complete');
            // trace('[XRay PatternMatchingCompiler] Used variables in case body: [${usedVarNames.join(", ")}]');
            // trace('[XRay PatternMatchingCompiler] Context set for enum parameter optimization');
            #end
            
            /**
             * CRITICAL CONTEXT TRACKING: Set current switch case body for orphaned parameter detection
             * 
             * WHY: EnumIntrospectionCompiler needs to analyze the case body AST to detect
             *      orphaned enum parameter extractions. This prevents generating unused 
             *      'g = elem(spec, N)' assignments for parameters that are never referenced.
             * 
             * WHAT: Set compiler.currentSwitchCaseBody to the case expression being compiled
             *       so that EnumIntrospectionCompiler can perform AST analysis.
             * 
             * HOW: Store the case body before compilation, clear it after compilation.
             *      This provides EnumIntrospectionCompiler with context to make intelligent
             *      decisions about whether to generate parameter extractions.
             * 
             * ARCHITECTURAL BENEFIT: Enables general-purpose orphaned parameter detection
             *                       without hardcoding specific enum names.
             */
            compiler.currentSwitchCaseBody = caseData.expr;
            #if debug_pattern_matching
            // trace('[XRay PatternMatchingCompiler] =====================================');
            // trace('[XRay PatternMatchingCompiler] ✓ SET switch case body context for orphaned parameter detection');
            // trace('[XRay PatternMatchingCompiler] Case body type: ${Type.enumConstructor(caseData.expr.expr)}');
            // trace('[XRay PatternMatchingCompiler] Case values count: ${caseData.values.length}');
            // trace('[XRay PatternMatchingCompiler] CONTEXT NOW AVAILABLE for enum parameter detection');
            // trace('[XRay PatternMatchingCompiler] =====================================');
            #end
            
            // No changes needed here - the fix should be in EnumIntrospectionCompiler itself
            var savedGMapping = null;
            
            // Check if the body is a TBlock and pass context for field assignment transformation
            var body = switch (caseData.expr.expr) {
                case TBlock(el):
                    #if debug_state_threading
                    // trace('[XRay compileStandardCase] TBlock case body with ${el.length} expressions');
                    // trace('[XRay compileStandardCase] Context: ${context != null ? "exists" : "null"}');
                    if (context != null) {
                        // trace('[XRay compileStandardCase] structParamName: ${context.structParamName}');
                    }
                    #end
                    // Filter out the TVar expressions used for pattern extraction
                    // Pass the pattern variables to the filter so it knows which extractions to keep
                    var filteredEl = filterPatternExtractionVars(el, patternVars);
                    // Pass context to ControlFlowCompiler for _this replacement
                    // Compile block directly
                    if (filteredEl.length == 0) {
                        "nil";
                    } else if (filteredEl.length == 1) {
                        compiler.compileExpression(filteredEl[0]);
                    } else {
                        filteredEl.map(e -> compiler.compileExpression(e)).join("\n");
                    }
                default:
                    #if debug_state_threading
                    // trace('[XRay compileStandardCase] Non-TBlock case body: ${caseData.expr.expr}');
                    // trace('[XRay compileStandardCase] Expression type: ${Type.enumConstructor(caseData.expr.expr)}');
                    // trace('[XRay compileStandardCase] Context: ${context != null ? "exists" : "null"}');
                    if (context != null) {
                        // trace('[XRay compileStandardCase] structParamName: ${context.structParamName}');
                    }
                    #end
                    // Check if this is a direct field assignment that needs transformation
                    if (context != null && context.structParamName != null) {
                        #if debug_state_threading
                        // trace('[XRay compileStandardCase] Checking for direct field assignment with context.structParamName = ${context.structParamName}');
                        #end
                        // Try to transform direct field assignments
                        // Direct field assignment analysis removed - compile normally
                        var directAssignment = null;
                        if (directAssignment != null) {
                            #if debug_state_threading
                            // trace('[XRay compileStandardCase] ✓ Direct assignment found, using transformed code');
                            // trace('[XRay compileStandardCase] Transformed: ${directAssignment.compiledCode}');
                            #end
                            directAssignment.compiledCode;
                        } else {
                            #if debug_state_threading
                            // trace('[XRay compileStandardCase] ✗ No direct assignment found, using normal compilation');
                            #end
                            compiler.compileExpression(caseData.expr);
                        }
                    } else {
                        #if debug_state_threading
                        // trace('[XRay compileStandardCase] ✗ No context or structParamName, using normal compilation');
                        #end
                        compiler.compileExpression(caseData.expr);
                    }
            };
            
            /**
             * CRITICAL CONTEXT CLEANUP: Clear switch case body context after compilation
             * 
             * WHY: Prevent context pollution and ensure currentSwitchCaseBody is only
             *      valid during the specific case being compiled.
             * 
             * WHAT: Reset compiler.currentSwitchCaseBody to null after case compilation
             * 
             * HOW: Clear the context immediately after body compilation to maintain
             *      clean state boundaries between different compilation contexts.
             */
            compiler.currentSwitchCaseBody = null;
            compiler.patternUsageContext = null;
            #if debug_pattern_matching
            // trace('[XRay PatternMatchingCompiler] ✓ CLEARED switch case body context');
            // trace('[XRay PatternMatchingCompiler] ✓ CLEARED pattern usage context');
            #end
            
            // Restore the saved mapping if we removed it
            // CRITICAL FIX: Don't restore if the mapping is to g_counter - that's always wrong
            if (savedGMapping != null && !StringTools.endsWith(savedGMapping, "_counter")) {
                compiler.currentFunctionParameterMap.set("g", savedGMapping);
                #if debug_pattern_matching
                // trace('[XRay PatternMatchingCompiler] RESTORED g -> ${savedGMapping} mapping after case body compilation');
                #end
            } else if (savedGMapping != null) {
                #if debug_pattern_matching
                // trace('[XRay PatternMatchingCompiler] ⚠️ BLOCKED restoration of incorrect g -> ${savedGMapping} mapping after case body');
                #end
            }
            
            for (pattern in patterns) {
                caseStrings.push('  ${pattern} -> ${body}');
            }
        }
        
        if (defaultExpr != null) {
            var defaultBody = compilePatternBody(defaultExpr, context);
            caseStrings.push('  _ -> ${defaultBody}');
        }
        
        return 'case ${exprStr} do\n${caseStrings.join("\n")}\nend';
    }
    
    /**
     * Compile Option switch to case statement
     */
    private function compileOptionSwitch(
        switchExpr: TypedExpr,
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>,
        defaultExpr: Null<TypedExpr>,
        ?context: FunctionContext
    ): String {
        
        /**
         * DEFINITIVE FIX: Keep variable mappings and extract actual variable
         * 
         * WHY: Same issue as in compileStandardCase - removing mappings causes
         *      mismatch between assignment variable and case variable.
         * 
         * WHAT: Compile with mappings intact and extract variable from assignment.
         * 
         * HOW: Parse 'variable = expression' pattern to get the actual variable.
         */
        var compiledExpr = compiler.compileExpression(switchExpr);
        var exprStr = compiledExpr;
        
        // Extract variable if an assignment was generated
        var assignmentPattern = ~/^([a-z_][a-zA-Z0-9_]*) = /;
        if (assignmentPattern.match(compiledExpr)) {
            exprStr = assignmentPattern.matched(1);
            #if debug_pattern_matching
//             trace('[compileOptionSwitch] ✓ Extracted variable from assignment: ${exprStr}');
            #end
        }
        var caseStrings: Array<String> = [];
        
        for (caseData in cases) {
            for (value in caseData.values) {
                var pattern = compileEnumPattern(value);
                var body = compilePatternBody(caseData.expr, context);
                caseStrings.push('  ${pattern} -> ${body}');
            }
        }
        
        if (defaultExpr != null) {
            var defaultBody = compilePatternBody(defaultExpr, context);
            caseStrings.push('  _ -> ${defaultBody}');
        }
        
        return 'case ${exprStr} do\n${caseStrings.join("\n")}\nend';
    }
    
    /**
     * Compile Result switch to case statement
     * 
     * WHY: Result<T,E> types should generate direct {:ok, value} | {:error, reason} pattern matching
     *      instead of double-nested case expressions with integer tags
     * 
     * WHAT: Transform Result enum switch directly to idiomatic Elixir patterns
     * 
     * HOW:
     * 1. Compile switch expression normally (without enum index extraction)
     * 2. Generate {:ok, _} and {:error, _} patterns directly from case values
     * 3. Avoid double-nesting by bypassing enum introspection for Result types
     */
    private function compileResultSwitch(
        switchExpr: TypedExpr,
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>,
        defaultExpr: Null<TypedExpr>,
        ?context: FunctionContext
    ): String {
        #if debug_pattern_matching
//         trace("[PatternMatchingCompiler] ✓ RESULT SWITCH COMPILATION - Generating direct patterns");
        #end
        
        /**
         * DEFINITIVE FIX: Keep variable mappings intact for Result switches too
         * 
         * WHY: Same as other switch functions - removing mappings breaks
         *      the TVar.id-based collision prevention system.
         *      
         * WHAT: Compile with mappings intact and extract variable from assignment.
         * 
         * HOW: Parse 'variable = expression' pattern to get the actual variable.
         */
        // Debug what we're about to compile
//         trace('[PatternMatchingCompiler] About to compile switch expression: ${switchExpr.expr}');
        
        // Special check for our problematic variables
        switch (switchExpr.expr) {
            case TLocal(v) if (v.name == "bulkAction" || v.name == "alertLevel"):
//                 trace('[PatternMatchingCompiler] ⚠️ COMPILING CAMELCASE VARIABLE: ${v.name}');
            case _:
        }
        
        var compiledExpr = compiler.compileExpression(switchExpr);
        var exprStr = compiledExpr;
        
        // Extract variable if an assignment was generated
        var assignmentPattern = ~/^([a-z_][a-zA-Z0-9_]*) = /;
        if (assignmentPattern.match(compiledExpr)) {
            exprStr = assignmentPattern.matched(1);
            #if debug_pattern_matching
//             trace('[compileResultSwitch] ✓ Extracted variable from assignment: ${exprStr}');
            #end
        }
//         trace('[PatternMatchingCompiler] Compiled switch expression to: ${exprStr}');
        
        // CRITICAL FIX: If the compiled expression contains a case statement, extract the variable
        // This handles situations where enum introspection was already applied
        if (exprStr.indexOf("case ") == 0 && exprStr.indexOf(" do ") > 0) {
            #if debug_pattern_matching
//             trace('[PatternMatchingCompiler] ⚠️ DETECTED ENUM INTROSPECTION in Result switch - extracting variable');
//             trace('[PatternMatchingCompiler] Original exprStr: ${exprStr}');
            #end
            
            // Extract the variable from "case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end"
            var caseStartIndex = exprStr.indexOf("case ") + 5;
            var doIndex = exprStr.indexOf(" do ");
            if (caseStartIndex < doIndex) {
                exprStr = exprStr.substring(caseStartIndex, doIndex);
                #if debug_pattern_matching
//                 trace('[PatternMatchingCompiler] ✓ EXTRACTED variable: ${exprStr}');
                #end
            }
        }
        
        // No longer need to restore mappings since we keep them intact
        
        var caseStrings: Array<String> = [];
        
        // Generate direct Result patterns for each case
        for (caseData in cases) {
            for (value in caseData.values) {
                #if debug_pattern_matching
//                 trace('[PatternMatchingCompiler] Processing Result case value: ${value.expr}');
                #end
                
                var pattern = switch (value.expr) {
                    case TConst(TInt(0)):
                        #if debug_pattern_matching
//                         trace('[PatternMatchingCompiler] ✓ OK pattern (index 0)');
                        #end
                        "{:ok, _}"; // Ok constructor
                        
                    case TConst(TInt(1)):
                        #if debug_pattern_matching
//                         trace('[PatternMatchingCompiler] ✓ ERROR pattern (index 1)');
                        #end
                        "{:error, _}"; // Error constructor
                        
                    case TCall(e, args):
                        // Handle direct enum constructor calls
                        switch (e.expr) {
                            case TField(_, FEnum(enumRef, enumField)):
                                var enumType = enumRef.get();
                                if (enumType.name == "Result") {
                                    compileResultPattern(enumField, args);
                                } else {
                                    compiler.compileExpression(value);
                                }
                            case _:
                                compiler.compileExpression(value);
                        }
                        
                    case _:
                        #if debug_pattern_matching
//                         trace('[PatternMatchingCompiler] ✓ FALLBACK pattern compilation');
                        #end
                        // Fall back to regular pattern compilation
                        compileEnumPattern(value);
                };
                
                var body = compilePatternBody(caseData.expr, context);
                caseStrings.push('  ${pattern} -> ${body}');
                
                #if debug_pattern_matching
//                 trace('[PatternMatchingCompiler] Generated Result case: ${pattern} -> [body]');
                #end
            }
        }
        
        if (defaultExpr != null) {
            var defaultBody = compilePatternBody(defaultExpr, context);
            caseStrings.push('  _ -> ${defaultBody}');
        }
        
        // CRITICAL FIX: Prevent incorrect variable mapping for compiler-generated switch variables
        // When Haxe desugars switch expressions, it creates temporary variables like 'g'.
        // These should NOT be mapped to loop counter names like 'g_counter'.
        // This is a direct fix to ensure the correct variable name is used.
        if (exprStr == "g_counter" && !compiler.variableRenameMap.exists("g_counter")) {
            // This is an incorrectly mapped variable - use the original 'g' instead
            exprStr = "g";
            #if debug_pattern_matching
//             trace('[PatternMatchingCompiler] WARNING: Fixed incorrect g_counter mapping to g');
            #end
        }
        
        var result = 'case ${exprStr} do\n${caseStrings.join("\n")}\nend';
        
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] ✓ RESULT SWITCH COMPLETE');
//         trace('[PatternMatchingCompiler] Generated: ${result.substring(0, 100)}...');
        #end
        
        return result;
    }
    
    /**
     * Filter out pattern extraction variables from a block
     * 
     * WHY: After extracting pattern variables and including them in the pattern,
     * we need to remove the TVar expressions that Haxe generated for extraction
     * to avoid duplicate variable assignments
     * 
     * WHY: When Haxe generates enum pattern matching with guards, it creates
     * nested TIf expressions that contain redundant pattern variable extractions.
     * These need to be filtered at all levels of the AST, not just the top level.
     * 
     * WHAT: Recursively processes expressions to remove:
     * 1. TVar expressions that extract enum parameters (_g variables) - BUT ONLY IF THEY ARE USED FOR PATTERNS
     * 2. TVar expressions that reassign pattern variables from extraction vars
     * 
     * HOW: Three-phase approach:
     * 1. Identify which extraction vars are used for pattern matching (not orphaned)
     * 2. Collect extraction variable names from the entire expression tree
     * 3. Filter and recursively transform expressions, removing only redundant assignments
     * 
     * @param el The block expressions to filter
     * @param patternVars Map of pattern variables extracted for this case (helps identify orphaned extractions)
     * @return Filtered expressions without pattern extraction code
     */
    private function filterPatternExtractionVars(el: Array<TypedExpr>, patternVars: Map<Int, String>): Array<TypedExpr> {
        #if debug_pattern_matching
        // trace("[XRay filterPatternExtractionVars] START - Processing ${el.length} expressions");
        // trace('[XRay filterPatternExtractionVars] Pattern vars count: ${Lambda.count(patternVars)}');
        #end
        
        // Phase 1: Identify which extraction vars are actually used for patterns (not orphaned)
        var usedExtractionVars = new Map<String, Int>(); // Maps extraction var name to param index
        var patternVarsByName = new Map<String, Int>(); // Maps pattern var name to param index
        
        // Build reverse mapping from pattern var names to indices
        for (idx in patternVars.keys()) {
            var varName = patternVars.get(idx);
            patternVarsByName.set(varName, idx);
        }
        
        // Find extraction vars that are used by pattern variables
        for (i in 0...el.length) {
            switch (el[i].expr) {
                case TVar(tvar, e):
                    if (StringTools.startsWith(tvar.name, "_g") && e != null) {
                        switch (e.expr) {
                            case TEnumParameter(_, enumField, index):
                                // Check if this extraction index is used by a pattern variable
                                if (patternVars.exists(index)) {
                                    usedExtractionVars.set(tvar.name, index);
                                    #if debug_pattern_matching
                                    // trace('[XRay filterPatternExtractionVars] ✓ Keeping extraction var ${tvar.name} (used for pattern param ${index})');
                                    #end
                                } else {
                                    #if debug_pattern_matching
                                    // trace('[XRay filterPatternExtractionVars] ✗ Marking orphaned extraction var ${tvar.name} (param ${index} not used in pattern)');
                                    #end
                                }
                            case _:
                        }
                    }
                case _:
            }
        }
        
        // Phase 2: Collect all extraction variable names from the entire tree (both used and orphaned)
        var allExtractionVars = new Map<String, Bool>();
        collectExtractionVarsRecursive(el, allExtractionVars);
        
        #if debug_pattern_matching
        // trace('[XRay filterPatternExtractionVars] Found extraction vars: ${[for (k in allExtractionVars.keys()) k]}');
        // trace('[XRay filterPatternExtractionVars] Used extraction vars: ${[for (k in usedExtractionVars.keys()) k]}');
        #end
        
        // Phase 3: Filter expressions recursively, but be smart about what to remove
        var filtered = [];
        for (expr in el) {
            var processedExpr = filterExpressionRecursive(expr, allExtractionVars, usedExtractionVars);
            if (processedExpr != null) {
                filtered.push(processedExpr);
            }
        }
        
        #if debug_pattern_matching
        // trace("[XRay filterPatternExtractionVars] END - Returning ${filtered.length} filtered expressions");
        #end
        
        return filtered;
    }
    
    /**
     * Recursively collect all extraction variable names from the expression tree
     */
    private function collectExtractionVarsRecursive(expressions: Array<TypedExpr>, extractionVars: Map<String, Bool>): Void {
        for (expr in expressions) {
            collectExtractionVarsFromExpr(expr, extractionVars);
        }
    }
    
    /**
     * Collect extraction variables from a single expression and its children
     */
    private function collectExtractionVarsFromExpr(expr: TypedExpr, extractionVars: Map<String, Bool>): Void {
        switch (expr.expr) {
            case TVar(tvar, e) if (StringTools.startsWith(tvar.name, "_g") && e != null):
                switch (e.expr) {
                    case TEnumParameter(_, _, _):
                        extractionVars.set(tvar.name, true);
                        #if debug_pattern_matching
                        // trace('[XRay collectExtractionVars] Found extraction var: ${tvar.name}');
                        #end
                    case _:
                }
            case TBlock(el):
                collectExtractionVarsRecursive(el, extractionVars);
            case TIf(cond, eif, eelse):
                collectExtractionVarsFromExpr(cond, extractionVars);
                collectExtractionVarsFromExpr(eif, extractionVars);
                if (eelse != null) {
                    collectExtractionVarsFromExpr(eelse, extractionVars);
                }
            case TWhile(cond, e, _):
                collectExtractionVarsFromExpr(cond, extractionVars);
                collectExtractionVarsFromExpr(e, extractionVars);
            case TFor(v, iter, e):
                collectExtractionVarsFromExpr(iter, extractionVars);
                collectExtractionVarsFromExpr(e, extractionVars);
            case TParenthesis(e):
                collectExtractionVarsFromExpr(e, extractionVars);
            case TSwitch(e, cases, edef):
                collectExtractionVarsFromExpr(e, extractionVars);
                for (c in cases) {
                    for (val in c.values) {
                        collectExtractionVarsFromExpr(val, extractionVars);
                    }
                    if (c.expr != null) {
                        collectExtractionVarsFromExpr(c.expr, extractionVars);
                    }
                }
                if (edef != null) {
                    collectExtractionVarsFromExpr(edef, extractionVars);
                }
            case _:
                // Other expression types don't need traversal for this purpose
        }
    }
    
    /**
     * Recursively filter an expression, removing pattern extraction code
     * and transforming nested structures
     * 
     * @param expr The expression to filter
     * @param allExtractionVars All extraction variables found in the tree
     * @param usedExtractionVars Extraction variables that are actually used for patterns (should be kept)
     * @return The filtered expression, or null if it should be removed entirely
     */
    private function filterExpressionRecursive(expr: TypedExpr, allExtractionVars: Map<String, Bool>, usedExtractionVars: Map<String, Int>): Null<TypedExpr> {
        switch (expr.expr) {
            case TVar(tvar, e):
                // Check if this should be filtered out - but be smart about it!
                if (StringTools.startsWith(tvar.name, "_g") && e != null) {
                    switch (e.expr) {
                        case TEnumParameter(_, _, _):
                            // CRITICAL FIX: Only filter out enum parameter extractions that are NOT used for patterns
                            if (!usedExtractionVars.exists(tvar.name)) {
                                #if debug_pattern_matching
                                // trace('[XRay filterExpression] Filtering out ORPHANED enum parameter extraction: ${tvar.name}');
                                #end
                                return null; // Skip orphaned enum parameter extraction
                            } else {
                                #if debug_pattern_matching
                                // trace('[XRay filterExpression] Keeping USED enum parameter extraction: ${tvar.name}');
                                #end
                                // Keep this extraction because it's used for pattern matching
                            }
                        case _:
                    }
                } else if (e != null) {
                    // Check if this is a redundant pattern variable assignment
                    switch (e.expr) {
                        case TLocal(v):
                            if (allExtractionVars.exists(v.name)) {
                                #if debug_pattern_matching
                                // trace('[XRay filterExpression] Filtering out pattern var assignment: ${tvar.name} = ${v.name}');
                                #end
                                return null; // Skip pattern variable assignment
                            }
                        case _:
                    }
                }
                return expr; // Keep other TVar expressions
                
            case TBlock(el):
                // Recursively filter block contents
                var filtered = [];
                for (e in el) {
                    var processedExpr = filterExpressionRecursive(e, allExtractionVars, usedExtractionVars);
                    if (processedExpr != null) {
                        filtered.push(processedExpr);
                    }
                }
                // Create new TBlock with filtered expressions
                return {
                    expr: TBlock(filtered),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TIf(cond, eif, eelse):
                // Recursively filter if branches
                #if debug_pattern_matching
                // trace("[XRay filterExpression] Processing TIf - filtering branches");
                #end
                
                var filteredIf = filterExpressionRecursive(eif, allExtractionVars, usedExtractionVars);
                var filteredElse = eelse != null ? filterExpressionRecursive(eelse, allExtractionVars, usedExtractionVars) : null;
                
                // Create new TIf with filtered branches
                return {
                    expr: TIf(cond, filteredIf != null ? filteredIf : eif, filteredElse),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TParenthesis(e):
                // Recursively filter parenthesis content
                var filtered = filterExpressionRecursive(e, allExtractionVars, usedExtractionVars);
                if (filtered != null) {
                    return {
                        expr: TParenthesis(filtered),
                        pos: expr.pos,
                        t: expr.t
                    };
                }
                return null;
                
            case TWhile(cond, e, normalWhile):
                // Recursively filter while body
                var filtered = filterExpressionRecursive(e, allExtractionVars, usedExtractionVars);
                if (filtered != null) {
                    return {
                        expr: TWhile(cond, filtered, normalWhile),
                        pos: expr.pos,
                        t: expr.t
                    };
                }
                return expr;
                
            case TFor(v, iter, e):
                // Recursively filter for body
                var filtered = filterExpressionRecursive(e, allExtractionVars, usedExtractionVars);
                if (filtered != null) {
                    return {
                        expr: TFor(v, iter, filtered),
                        pos: expr.pos,
                        t: expr.t
                    };
                }
                return expr;
                
            default:
                // Keep other expressions as-is
                return expr;
        }
    }
    
    /**
     * RECURSIVE HELPER: Find pattern variable assignments that use extraction variables
     * 
     * WHY: Pattern variable assignments like TVar(config, TLocal(_g)) can be nested
     * inside TBlock expressions, not just at the top level. This function recursively
     * searches through all expressions to find these assignments.
     * 
     * WHAT: Recursively searches expressions for TVar assignments that reference
     * extraction variables, updating the patternVars map with found mappings
     * 
     * HOW: Uses recursive traversal to examine TBlock, TIf, and other nested structures
     * 
     * @param expressions List of expressions to search
     * @param extractionVars Map of extraction variable names to parameter indices  
     * @param patternVars Map to update with found pattern variable mappings
     */
    private function findPatternVariableAssignments(expressions: Array<TypedExpr>, 
                                                   extractionVars: Map<String, Int>, 
                                                   patternVars: Map<Int, String>): Void {
        for (expr in expressions) {
            switch (expr.expr) {
                case TVar(patternVar, assignExpr) if (assignExpr != null):
                    switch (assignExpr.expr) {
                        case TLocal(v):
                            if (extractionVars.exists(v.name)) {
                                var paramIndex = extractionVars.get(v.name);
                                
                                // Check if the variable is marked as unused by Reflaxe preprocessor
                                var isUnused = patternVar.meta != null && patternVar.meta.has("-reflaxe.unused");
                                var varName = NamingHelper.toSnakeCase(patternVar.name);
                                
                                // Prefix with underscore if unused to avoid compilation warnings
                                if (isUnused && !StringTools.startsWith(varName, "_")) {
                                    varName = "_" + varName;
                                }
                                
                                patternVars.set(paramIndex, varName);
                                #if debug_pattern_matching
                                // trace('[XRay PatternMatchingCompiler] ✓ Mapped param ${paramIndex} to variable: ${varName} (via ${v.name}, unused=${isUnused})');
                                #end
                            }
                        case _:
                    }
                case TBlock(el):
                    // Recurse into nested blocks
                    #if debug_pattern_matching
                    // trace('[XRay PatternMatchingCompiler] Recursing into TBlock with ${el.length} expressions');
                    #end
                    findPatternVariableAssignments(el, extractionVars, patternVars);
                case TIf(econd, eif, eelse):
                    // Recurse into if branches (less common but possible)
                    findPatternVariableAssignments([eif], extractionVars, patternVars);
                    if (eelse != null) {
                        findPatternVariableAssignments([eelse], extractionVars, patternVars);
                    }
                case _:
                    // Other expressions types don't typically contain nested variable assignments
            }
        }
    }
    
    /**
     * Extract pattern variables from a case body
     * 
     * WHY: Haxe generates TEnumParameter followed by TVar assignments in the case body
     * instead of including variables directly in the pattern. We need to extract these
     * to generate proper Elixir patterns like {:rgb, r, g, b} instead of {:rgb, _, _, _}
     * 
     * @param expr The case body expression to analyze
     * @return Map of parameter index to variable name
     */
    private function extractPatternVariables(expr: TypedExpr): Map<Int, String> {
        var patternVars = new Map<Int, String>();
        
        #if debug_pattern_matching
        // trace("[XRay PatternMatchingCompiler] Extracting pattern variables from case body");
        #end
        
        switch (expr.expr) {
            case TBlock(el):
                #if debug_pattern_matching
                // trace('[XRay PatternMatchingCompiler] Block has ${el.length} expressions');
                for (k in 0...Std.int(Math.min(el.length, 10))) {
                    var exprStr = switch(el[k].expr) {
                        case TVar(tvar, e):
                            var initStr = e != null ? switch(e.expr) {
                                case TEnumParameter(_, ef, idx): 'TEnumParameter(${ef.name}, idx=${idx})';
                                case TLocal(v): 'TLocal(${v.name})';
                                case TConst(c): 'TConst(${c})';
                                case _: Std.string(e.expr);
                            } : "null";
                            'TVar(${tvar.name}, ${initStr})';
                        case TIf(cond, e1, e2):
                            'TIf(...)';
                        case _: 
                            Std.string(el[k].expr);
                    };
                    // trace('[XRay PatternMatchingCompiler] el[${k}]: ${exprStr}');
                }
                #end
                
                // First pass: Find all enum parameter extractions and map them
                var extractionVars = new Map<String, Int>(); // Maps extraction var name to param index
                for (i in 0...el.length) {
                    switch (el[i].expr) {
                        case TVar(tvar, e):
                            #if debug_pattern_matching
                            // trace('[XRay PatternMatchingCompiler] Checking TVar: name="${tvar.name}", startsWith(_g)=${StringTools.startsWith(tvar.name, "_g")}, e!=null=${e != null}');
                            #end
                            if (StringTools.startsWith(tvar.name, "_g") && e != null) {
                                switch (e.expr) {
                                    case TEnumParameter(_, enumField, index):
                                        extractionVars.set(tvar.name, index);
                                        #if debug_pattern_matching
                                        // trace('[XRay PatternMatchingCompiler] ✓ Found extraction: ${tvar.name} -> param ${index}');
                                        #end
                                    case _:
                                        #if debug_pattern_matching
                                        // trace('[XRay PatternMatchingCompiler] TVar ${tvar.name} has non-TEnumParameter init: ${e.expr}');
                                        #end
                                }
                            }
                        case _:
                    }
                }
                
                // Second pass: Find pattern variable assignments that use these extraction vars (recursive)
                findPatternVariableAssignments(el, extractionVars, patternVars);
            case _:
                #if debug_pattern_matching
                // trace('[XRay PatternMatchingCompiler] Case body is not TBlock: ${expr.expr}');
                #end
        }
        
        #if debug_pattern_matching
        // trace('[XRay PatternMatchingCompiler] Extracted ${Lambda.count(patternVars)} pattern variables');
        for (key in patternVars.keys()) {
            // trace('[XRay PatternMatchingCompiler]   Param ${key}: ${patternVars.get(key)}');
        }
        #end
        
        return patternVars;
    }
    
    /**
     * Compile pattern with extracted variables
     * 
     * WHY: Generate proper Elixir patterns with variable bindings like {:rgb, r, g, b}
     * instead of wildcards {:rgb, _, _, _}
     * 
     * @param expr The pattern expression
     * @param patternVars Map of parameter index to variable name
     * @param caseBody The case body expression for usage detection (optional)
     * @return Compiled pattern string with variables
     */
    private function compilePatternWithVariables(expr: TypedExpr, patternVars: Map<Int, String>, ?caseBody: TypedExpr): String {
        #if debug_pattern_matching
        // trace('[XRay PatternMatchingCompiler] compilePatternWithVariables: expr=${expr.expr}, patternVars=${patternVars}');
        #end
        
        return switch (expr.expr) {
            case TConst(TInt(n)):
                // This is just a simple integer match (like case 3:)
                // If we have pattern variables, this means the case body extracts enum parameters
                // We need to generate the pattern differently
                
                // CRITICAL FIX: Check if this is an elem() based switch
                // If the switch expression uses elem(expr, 0), patterns should be simple integers
                // If the switch expression is the enum itself, patterns should be tuples
                if (Lambda.count(patternVars) > 0 && !isElemBasedSwitch()) {
                    // This is an enum constructor match with parameters using direct enum destructuring
                    // Generate the pattern with the extracted variables
                    var varList = [];
                    for (i in 0...Lambda.count(patternVars)) {
                        if (patternVars.exists(i)) {
                            var varName = patternVars.get(i);
                            var originalName = varName;
                            
                            /**
                             * CRITICAL FIX: Haxe Variable Renaming in Enum Pattern Matching
                             * 
                             * === WHY DOES HAXE RENAME VARIABLES? ===
                             * 
                             * Haxe's compiler enforces STRICT LEXICAL SCOPING to prevent variable shadowing
                             * bugs that are common in JavaScript and other languages. Variable shadowing occurs
                             * when an inner scope variable has the same name as an outer scope variable,
                             * potentially leading to confusion about which variable is being referenced.
                             * 
                             * THE RENAMING MECHANISM:
                             * 1. Haxe's typer phase detects naming conflicts during AST construction
                             * 2. When a pattern variable would shadow an existing variable in scope,
                             *    Haxe automatically renames it by appending a numeric suffix
                             * 3. The suffix increments to ensure uniqueness (spec → spec2 → spec3, etc.)
                             * 4. This happens BEFORE our transpiler sees the AST - it's baked into TypedExpr
                             * 
                             * Example scenario:
                             * ```haxe
                             * function toLegacy(spec: ChildSpec, action: TypeSafeChildSpec) {
                             *     return switch(action) {
                             *         case Legacy(spec):  // 'spec' would shadow the function parameter
                             *             spec;           // Which 'spec'? Function param or pattern var?
                             *     }
                             * }
                             * ```
                             * 
                             * What Haxe does internally:
                             * - Detects: Pattern variable 'spec' shadows parameter 'spec'
                             * - Renames: Pattern variable becomes 'spec2' in the TypedExpr AST
                             * - Maintains: All references within that scope use 'spec2'
                             * - Result: No ambiguity about which variable is referenced
                             * 
                             * This is a FEATURE in Haxe that prevents common scoping bugs, but
                             * it creates challenges for our Elixir transpiler (explained below).
                             * 
                             * === WHY IS THIS A PROBLEM FOR ELIXIR? ===
                             * 
                             * Elixir's pattern matching syntax requires EXACT variable name consistency:
                             * 
                             * WRONG (causes "undefined variable spec" error):
                             * ```elixir
                             * case action do
                             *   {6, spec2} ->     # Pattern binds 'spec2'
                             *     spec            # Body references 'spec' - UNDEFINED!
                             * end
                             * ```
                             * 
                             * CORRECT:
                             * ```elixir
                             * case action do
                             *   {6, spec} ->      # Pattern binds 'spec'
                             *     spec            # Body references 'spec' - WORKS!
                             * end
                             * ```
                             * 
                             * Unlike Haxe which tracks variables by ID, Elixir uses name-based binding.
                             * If the pattern binds 'spec2' but the body uses 'spec', Elixir has no way
                             * to know they're meant to be the same variable.
                             * 
                             * === THE COMPILATION FLOW ===
                             * 
                             * 1. HAXE SOURCE: case Legacy(spec): spec
                             * 
                             * 2. HAXE AST (after renaming): 
                             *    - Pattern: TCall(Legacy, [TLocal(spec2)])  // Renamed!
                             *    - Body: TLocal(spec2)                       // Also renamed in AST
                             * 
                             * 3. OUR PATTERN EXTRACTION:
                             *    - We extract "spec2" from the pattern TLocal
                             * 
                             * 4. OUR VARIABLE MAPPING:
                             *    - VariableCompiler maps spec2 → spec (strips suffix)
                             *    - This makes the body compile to 'spec'
                             * 
                             * 5. THE MISMATCH:
                             *    - Pattern: {6, spec2} (from AST name)
                             *    - Body: spec (from VariableCompiler mapping)
                             *    - Result: UNDEFINED VARIABLE ERROR
                             * 
                             * === THE SOLUTION ===
                             * 
                             * Strip numeric suffixes from renamed variables in pattern generation.
                             * This ensures the pattern uses the same name the body will use after
                             * VariableCompiler processes it.
                             * 
                             * Detection methods:
                             * 1. PRIMARY: Check -reflaxe.renamed metadata (set by preprocessor)
                             * 2. FALLBACK: Detect numeric suffix pattern (spec2 → spec)
                             * 
                             * === ELIXIR-SPECIFIC CONSIDERATIONS ===
                             * 
                             * This issue is unique to the Elixir target because:
                             * - Elixir pattern matching binds variables by NAME
                             * - Other targets (JS, C++, etc.) use different variable binding mechanisms
                             * - Elixir's immutability means no variable reassignment to fix mismatches
                             * - Pattern matching is central to Elixir idioms (unlike imperative targets)
                             */
                            if (~/^(.+?)([0-9]+)$/.match(varName)) {
                                // Extract base name without number suffix (spec2 → spec)
                                originalName = ~/^(.+?)([0-9]+)$/.replace(varName, "$1");
                                #if debug_pattern_matching
                                // trace('[XRay PatternMatchingCompiler] RENAME DETECTED: Haxe renamed "${originalName}" to "${varName}" to avoid shadowing');
                                // trace('[XRay PatternMatchingCompiler] Using original name "${originalName}" in pattern for consistency');
                                #end
                            }
                            
                            /**
                             * USAGE DETECTION:
                             * 
                             * At this point we only have variable names (strings) from patternVars.
                             * The metadata was already checked when extracting the variables from TCall.
                             * 
                             * For renamed variables (where originalName differs from varName), we assume
                             * they're used to avoid runtime errors. The preprocessor would have marked
                             * truly unused variables with -reflaxe.unused metadata, which we'll check
                             * in other contexts where we have access to TVar objects.
                             */
                            var isUsed = false;
                            
                            if (varName != originalName) {
                                // Variable was renamed (spec2 -> spec), assume it's used for safety
                                isUsed = true;
                                #if debug_pattern_matching
                                // trace('[XRay PatternMatchingCompiler] Renamed "${varName}"→"${originalName}", assuming used');
                                #end
                            } else if (caseBody != null) {
                                // Check if variable is used in the body
                                isUsed = isVariableUsedInExpression(caseBody, originalName);
                            }
                            
                            if (!isUsed) {
                                // Variable not used - prefix with underscore
                                varList.push("_" + originalName);
                                #if debug_pattern_matching
                                // trace('[XRay PatternMatchingCompiler] Variable "${originalName}" not used in case body, prefixing with underscore');
                                #end
                            } else {
                                // Variable is used - use the original name
                                varList.push(originalName);
                                #if debug_pattern_matching
                                // trace('[XRay PatternMatchingCompiler] Variable "${originalName}" IS used in case body, no prefix needed');
                                #end
                            }
                        } else {
                            varList.push("_");
                        }
                    }
                    #if debug_pattern_matching
                    // trace('[XRay PatternMatchingCompiler] Generating enum tuple pattern for index ${n}: {${n}, ${varList.join(", ")}}');
                    #end
                    
                    // For integer patterns with variables, generate tuple pattern
                    if (varList.length > 0) {
                        '{${n}, ${varList.join(", ")}}';
                    } else {
                        Std.string(n);
                    }
                } else {
                    // Simple integer pattern - either no variables or elem() based switch
                    #if debug_pattern_matching
                    if (Lambda.count(patternVars) > 0) {
                        // trace('[XRay PatternMatchingCompiler] Generating simple integer pattern for elem() switch: ${n}');
                    } else {
                        // trace('[XRay PatternMatchingCompiler] Generating simple integer pattern: ${n}');
                    }
                    #end
                    Std.string(n);
                }
                
            case TCall(e, args):
                switch (e.expr) {
                    case TField(_, FEnum(enumRef, enumField)):
                        var enumType = enumRef.get();
                        
                        // Generate pattern with extracted variable names
                        var argPatterns = [];
                        
                        // Use patternVars if available, otherwise use args
                        var numParams = Std.int(Math.max(args.length, Lambda.count(patternVars)));
                        for (i in 0...numParams) {
                            if (patternVars.exists(i)) {
                                argPatterns.push(patternVars.get(i));
                            } else if (i < args.length) {
                                // Compile the argument pattern
                                argPatterns.push(compilePatternArgument(args[i]));
                            } else {
                                // Use wildcard if no variable found
                                argPatterns.push("_");
                            }
                        }
                        
                        // Check for special enum types
                        if (enumType.name == "Option") {
                            compileOptionPatternWithVars(enumField, argPatterns);
                        } else if (enumType.name == "Result") {
                            compileResultPatternWithVars(enumField, argPatterns);
                        } else {
                            // Standard enum pattern
                            compileTuplePatternWithVars(enumField.name, argPatterns);
                        }
                        
                    default:
                        compilePattern(expr);
                }
                
            default:
                compilePattern(expr);
        };
    }
    
    /**
     * Compile enum pattern with automatic usage detection
     * 
     * WHY: We need to detect which pattern variables are actually used in the case body
     * to properly prefix unused ones with underscore and avoid compilation warnings.
     * 
     * WHAT: Analyzes the case body for variable usage and generates patterns accordingly
     * 
     * HOW: For each pattern variable, checks if it's referenced in the case body expression
     * and prefixes with underscore if unused
     * 
     * @param constructorName The enum constructor name
     * @param args The constructor arguments
     * @param caseBody The case body expression to analyze for variable usage
     * @return Compiled pattern string with appropriate underscore prefixing
     */
    private function compileEnumPatternWithUsageDetection(constructorName: String, args: Array<TypedExpr>, caseBody: TypedExpr): String {
        var atom = ':${NamingHelper.toSnakeCase(constructorName)}';
        
        if (args.length == 0) {
            return atom;
        }
        
        var argPatterns = [];
        for (arg in args) {
            var pattern = switch (arg.expr) {
                case TLocal(v):
                    var varName = v.name;
                    var snakeName = NamingHelper.toSnakeCase(varName);
                    
                    // Check if this variable is used in the case body
                    var isUsed = isVariableUsedInExpression(caseBody, varName);
                    
                    // Prefix with underscore if unused
                    if (!isUsed && !StringTools.startsWith(snakeName, "_")) {
                        "_" + snakeName;
                    } else {
                        snakeName;
                    }
                    
                case _:
                    // Non-variable patterns compile normally
                    compilePatternArgument(arg);
            };
            argPatterns.push(pattern);
        }
        
        return '{${atom}, ${argPatterns.join(", ")}}';
    }
    
    /**
     * Compile tuple pattern with variable names
     */
    private function compileTuplePatternWithVars(constructorName: String, argPatterns: Array<String>): String {
        if (argPatterns.length == 0) {
            return ':${NamingHelper.toSnakeCase(constructorName)}';
        }
        
        var args = argPatterns.join(", ");
        return '{:${NamingHelper.toSnakeCase(constructorName)}, ${args}}';
    }
    
    /**
     * Compile Option pattern with variable names
     */
    private function compileOptionPatternWithVars(enumField: EnumField, argPatterns: Array<String>): String {
        return switch (enumField.name) {
            case "Some":
                if (argPatterns.length > 0) {
                    '{:some, ${argPatterns[0]}}';
                } else {
                    '{:some, nil}';
                }
            case "None":
                ':none';
            default:
                compileTuplePatternWithVars(enumField.name, argPatterns);
        };
    }
    
    /**
     * Compile Result pattern with variable names
     */
    private function compileResultPatternWithVars(enumField: EnumField, argPatterns: Array<String>): String {
        return switch (enumField.name) {
            case "Ok":
                if (argPatterns.length > 0) {
                    '{:ok, ${argPatterns[0]}}';
                } else {
                    '{:ok, nil}';
                }
            case "Error":
                if (argPatterns.length > 0) {
                    '{:error, ${argPatterns[0]}}';
                } else {
                    '{:error, nil}';
                }
            default:
                compileTuplePatternWithVars(enumField.name, argPatterns);
        };
    }
    
    /**
     * Compile a pattern from an expression
     */
    private function compilePattern(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TConst(c):
                // TConstant from typed AST - use LiteralCompiler for proper handling
                // See compilePatternArgument above for detailed explanation of TConstant vs Constant
                compiler.expressionDispatcher.literalCompiler.compileConstant(c);
                
            case TCall(_, _):
                compileEnumPattern(expr);
                
            case TLocal(v):
                NamingHelper.toSnakeCase(v.name);
                
            default:
                compiler.compileExpression(expr);
        };
    }
    
    /**
     * Compile tuple pattern for enum constructors
     */
    private function compileTuplePattern(name: String, args: Array<TypedExpr>): String {
        var atom = ':${NamingHelper.toSnakeCase(name)}';
        
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] compileTuplePattern called');
//         trace('[PatternMatchingCompiler]   name: ${name}');
//         trace('[PatternMatchingCompiler]   args.length: ${args.length}');
        for (i in 0...args.length) {
//             trace('[PatternMatchingCompiler]   arg[${i}]: ${args[i].expr}');
        }
        #end
        
        if (args.length == 0) {
            #if debug_pattern_matching
//             trace('[PatternMatchingCompiler]   -> Returning atom: ${atom}');
            #end
            return atom;
        }
        
        var argPatterns = args.map(arg -> compilePatternArgument(arg));
        var result = '{${atom}, ${argPatterns.join(", ")}}';
        
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler]   -> Returning tuple: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Check if pattern represents a success case
     */
    private function isSuccessPattern(pattern: String): Bool {
        return pattern.indexOf("{:ok,") == 0 || 
               pattern.indexOf("{:some,") == 0;
    }
    
    /**
     * Compile pattern body expression with field assignment detection
     * 
     * WHY: Case body expressions can contain sequential field assignments that need transformation
     * WHAT: Apply the same field assignment detection as ControlFlowCompiler.compileBlock
     * HOW: Check if expression is TBlock, if so delegate to ControlFlowCompiler, otherwise use normal compilation
     * 
     * @param expr The case body expression
     * @return Compiled expression with field assignment transformations applied
     */
    private function compilePatternBody(expr: TypedExpr, ?context: FunctionContext): String {
        #if debug_pattern_matching
        // trace("[XRay PatternMatchingCompiler] CASE BODY COMPILATION START");
        // trace('[XRay PatternMatchingCompiler] Body expression type: ${expr.expr}');
        // trace('[XRay PatternMatchingCompiler] Context received: ${context != null ? "yes" : "no"}');
        if (context != null && context.structParamName != null) {
            // trace('[XRay PatternMatchingCompiler] Context structParamName: ${context.structParamName}');
        }
        #end
        
        return switch (expr.expr) {
            case TBlock(el):
                #if debug_pattern_matching
                // trace("[XRay PatternMatchingCompiler] ✓ DELEGATING TBlock to ControlFlowCompiler");
                // trace('[XRay PatternMatchingCompiler] Block has ${el.length} expressions');
                for (i in 0...el.length) {
                    // trace('[XRay PatternMatchingCompiler] Expression ${i}: ${el[i].expr}');
                }
                // trace('[XRay PatternMatchingCompiler] Passing context to compileBlock: ${context != null ? "yes" : "no"}');
                #end
                
                // Use the passed context if available, otherwise don't pass context
                // This allows proper state threading transformation when context is provided
                // Compile block directly
                var result = if (el.length == 0) {
                    "nil";
                } else if (el.length == 1) {
                    compiler.compileExpression(el[0]);
                } else {
                    el.map(e -> compiler.compileExpression(e)).join("\n");
                }
                
                #if debug_pattern_matching
                // trace('[XRay PatternMatchingCompiler] ControlFlowCompiler result: ${result.substring(0, 100)}...');
                #end
                
                result;
                
            case TParenthesis(e):
                #if debug_pattern_matching
                // trace("[XRay PatternMatchingCompiler] ✓ FOUND TParenthesis wrapping another expression");
                // trace('[XRay PatternMatchingCompiler] Inner expression type: ${e.expr}');
                #end
                
                // Recursively process the parentheses content - this might be a TBlock!
                var result = compilePatternBody(e, context);
                
                #if debug_pattern_matching
                // trace('[XRay PatternMatchingCompiler] TParenthesis result: ${result.substring(0, 100)}...');
                #end
                
                // The parentheses are already handled by the inner expression
                result;
                
            case _:
                #if debug_pattern_matching
                // trace("[XRay PatternMatchingCompiler] ✓ USING standard compilation for non-block");
                // trace('[XRay PatternMatchingCompiler] Context available: ${context != null}');
                if (context != null) {
                    // trace('[XRay PatternMatchingCompiler] structParamName: ${context.structParamName}');
                }
                #end
                
                // If we have context, temporarily set parameter mapping for _this replacement
                var hadMapping = false;
                var originalMapping = null;
                if (context != null && context.structParamName != null) {
                    originalMapping = compiler.currentFunctionParameterMap.get("_this");
                    hadMapping = originalMapping != null;
                    compiler.currentFunctionParameterMap.set("_this", context.structParamName);
                    
                    #if debug_pattern_matching
                    // trace('[XRay PatternMatchingCompiler] ✓ Set temporary _this mapping to: ${context.structParamName}');
                    #end
                }
                
                // Normal expression compilation for non-block expressions
                var result = compiler.compileExpression(expr);
                
                // Restore original mapping state
                if (context != null && context.structParamName != null) {
                    if (hadMapping) {
                        compiler.currentFunctionParameterMap.set("_this", originalMapping);
                    } else {
                        compiler.currentFunctionParameterMap.remove("_this");
                    }
                    
                    #if debug_pattern_matching
                    // trace('[XRay PatternMatchingCompiler] ✓ Restored original _this mapping state');
                    #end
                }
                
                #if debug_pattern_matching
                // trace('[XRay PatternMatchingCompiler] Standard result: ${result.substring(0, 100)}...');
                #end
                
                result;
        };
    }
    
    /**
     * Check if expression is a success constructor
     */
    private function isSuccessConstructor(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TCall(e, _):
                switch (e.expr) {
                    case TField(_, FEnum(_, enumField)):
                        enumField.name == "Ok" || enumField.name == "Some";
                    default:
                        false;
                }
            default:
                false;
        };
    }
    
    /**
     * Detect TSwitch(TEnumIndex(expr)) patterns that create double-nested case expressions
     * 
     * WHY: TEnumIndex expressions get compiled independently by EnumIntrospectionCompiler,
     *      creating inner case statements. When TSwitch then switches on these results,
     *      we get double-nested patterns like: case (case g do {:ok, _} -> 0; ... end) do
     * 
     * WHAT: Detect TEnumIndex expressions within switch expressions for direct compilation
     * 
     * HOW: Check if the switch expression is a TEnumIndex of a Result/Option type
     * 
     * @param switchExpr The expression being switched on
     * @return True if this is a TSwitch(TEnumIndex) pattern
     */
    private function isSwitchOnEnumIndex(switchExpr: TypedExpr): Bool {
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] Checking for TEnumIndex pattern in switch expression');
//         trace('[PatternMatchingCompiler] Switch expr type: ${switchExpr.expr}');
        #end
        
        // CRITICAL FIX: Unwrap TParenthesis and TMeta layers to find underlying TEnumIndex
        // This is necessary because expressions like switch((topic)) are wrapped in parentheses
        var unwrappedExpr = switchExpr;
        while (true) {
            switch (unwrappedExpr.expr) {
                case TParenthesis(innerExpr):
                    unwrappedExpr = innerExpr;
                    #if debug_pattern_matching
//                     trace('[PatternMatchingCompiler] Unwrapped TParenthesis, now: ${unwrappedExpr.expr}');
                    #end
                case TMeta(_, innerExpr):
                    unwrappedExpr = innerExpr;
                    #if debug_pattern_matching
//                     trace('[PatternMatchingCompiler] Unwrapped TMeta, now: ${unwrappedExpr.expr}');
                    #end
                case _:
                    break;
            }
        }
        
        switch (unwrappedExpr.expr) {
            case TEnumIndex(innerExpr):
                #if debug_pattern_matching
//                 trace('[PatternMatchingCompiler] ✓ Found TEnumIndex pattern after unwrapping!');
//                 trace('[PatternMatchingCompiler] Inner expr type: ${innerExpr.t}');
                #end
                
                // Check if the inner expression is an enum type
                // We want to handle ALL enums directly to avoid double-nested case statements
                switch (innerExpr.t) {
                    case TEnum(enumRef, _):
                        var enumType = enumRef.get();
                        #if debug_pattern_matching
//                         trace('[PatternMatchingCompiler] Enum type: ${enumType.name} - will use direct compilation');
                        #end
                        // Return true for ALL enum types to avoid double-nested case statements
                        // The compileSwitchOnEnumIndexDirectly method will handle different enum types appropriately
                        return true;
                    case _:
                        #if debug_pattern_matching
//                         trace('[PatternMatchingCompiler] Inner expr is not enum type');
                        #end
                        return false;
                }
            case _:
                #if debug_pattern_matching
//                 trace('[PatternMatchingCompiler] Not a TEnumIndex pattern even after unwrapping');
                #end
                return false;
        }
    }
    
    /**
     * Compile TSwitch(TEnumIndex(expr)) directly to clean case statement
     * 
     * WHY: Bypass EnumIntrospectionCompiler to prevent double-nested case expressions
     * 
     * WHAT: Generate direct pattern matching for Result/Option types instead of
     *       switching on enum index integers
     * 
     * HOW: Extract the inner expression from TEnumIndex and generate direct patterns
     * 
     * @param switchExpr The TEnumIndex expression being switched on
     * @param cases The switch cases (should be integer patterns)
     * @param defaultExpr Default case expression
     * @param context Function context for parameter mapping
     * @return Clean Elixir case statement
     */
    private function compileSwitchOnEnumIndexDirectly(
        switchExpr: TypedExpr, 
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, 
        defaultExpr: Null<TypedExpr>,
        ?context: FunctionContext
    ): String {
        #if debug_pattern_matching
//         trace("[PatternMatchingCompiler] ✓ DIRECT TSwitch(TEnumIndex) COMPILATION START");
        #end
        
        // Extract the inner expression from TEnumIndex
        var innerExpr = switch (switchExpr.expr) {
            case TEnumIndex(expr): expr;
            case _: 
                #if debug_pattern_matching
//                 trace("[PatternMatchingCompiler] ❌ ERROR: Not a TEnumIndex expression");
                #end
                return compileStandardCase(switchExpr, cases, defaultExpr, context);
        };
        
        // Determine the enum type
        var enumType = switch (innerExpr.t) {
            case TEnum(enumRef, _): enumRef.get();
            case _: 
                #if debug_pattern_matching
//                 trace("[PatternMatchingCompiler] ❌ ERROR: Inner expression is not enum type");
                #end
                return compileStandardCase(switchExpr, cases, defaultExpr, context);
        };
        
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] Enum type: ${enumType.name}');
        #end
        
        /**
         * DEFINITIVE FIX: Keep variable mappings intact
         * 
         * WHY: The Go compiler and other Reflaxe compilers don't manipulate
         *      variable mappings during switch compilation. They just compile
         *      the expression directly with whatever mappings are active.
         *      
         * WHAT: Compile the inner expression with mappings intact, then extract
         *       the variable if an assignment was generated.
         *       
         * HOW: Same approach as other switch functions - parse assignments.
         * 
         * NOTE: This is NOT a band-aid. Other Reflaxe compilers (Go, C++, C#)
         *       don't remove mappings either - they work with the mapping
         *       system, not against it.
         */
        // Compile the inner expression directly with mappings intact
        var compiledExpr = compiler.compileExpression(innerExpr);
        var innerExprStr = compiledExpr;
        
        // Extract variable if an assignment was generated
        var assignmentPattern = ~/^([a-z_][a-zA-Z0-9_]*) = /;
        if (assignmentPattern.match(compiledExpr)) {
            innerExprStr = assignmentPattern.matched(1);
            #if debug_pattern_matching
//             trace('[compileSwitchOnEnumIndexDirectly] ✓ Extracted variable from assignment: ${innerExprStr}');
            #end
        }
        
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] Inner expression compiled to: ${innerExprStr}');
        #end
        
        // Generate direct patterns based on enum type
        var caseStrings: Array<String> = [];
        
        // Check if this enum has parameters by analyzing the actual case patterns
        // CRITICAL FIX: construct.params.length returns 0 incorrectly for some enums
        // Instead, detect parameters from the case body using TEnumParameter
        var hasParameters = false;
        var constructorHasParams = new Map<Int, Bool>(); 
        
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] Analyzing enum ${enumType.name} - checking case bodies for parameter usage');
        #end
        
        // Analyze case bodies to detect if they extract enum parameters
        for (i in 0...cases.length) {
            var caseData = cases[i];
            // Check if the case body contains TEnumParameter expressions
            var usesEnumParams = containsEnumParameter(caseData.expr);
            if (usesEnumParams) {
                hasParameters = true;
                for (value in caseData.values) {
                    switch (value.expr) {
                        case TConst(TInt(index)):
                            constructorHasParams.set(index, true);
                            #if debug_pattern_matching
//                             trace('[PatternMatchingCompiler] Constructor at index ${index} uses parameters (found TEnumParameter in body)');
                            #end
                        case _:
                    }
                }
            }
        }
        
        #if debug_pattern_matching  
//         trace('[PatternMatchingCompiler] Enum ${enumType.name} has parameters: ${hasParameters} (detected from case bodies)');
        #end
        
        for (caseData in cases) {
            for (value in caseData.values) {
                var pattern = switch (value.expr) {
                    case TConst(TInt(index)):
                        // Special handling for Result/Option types
                        if (enumType.name == "Result") {
                            index == 0 ? "{:ok, _}" : "{:error, _}";
                        } else if (enumType.name == "Option") {
                            index == 0 ? "{:ok, _}" : ":error";
                        } else if (!hasParameters) {
                            // For enums without parameters, generate atom patterns directly
                            // Map index to constructor name
                            if (index >= 0 && index < enumType.names.length) {
                                var constructorName = enumType.names[index];
                                ':' + NamingHelper.toSnakeCase(constructorName);
                            } else {
                                "_"; // Fallback for out-of-bounds index
                            }
                        } else {
                            // CRITICAL FIX: For enums with parameters, use INTEGER PATTERNS
                            // The switch is on elem(message, 0) which returns the constructor index
                            if (index >= 0 && index < enumType.names.length) {
                                '${index}';
                            } else {
                                "_"; // Fallback
                            }
                        };
                    case _: "_"; // Catch-all for non-constant patterns
                };
                
                // CRITICAL FIX: Generate parameter extraction for constructors with parameters
                var parameterExtractionStatements = "";
                if (hasParameters) {
                    // Check if this specific constructor has parameters
                    var constructorIndex = switch (value.expr) {
                        case TConst(TInt(i)): i;
                        case _: -1;
                    };
                    
                    if (constructorIndex >= 0 && constructorHasParams.get(constructorIndex) == true) {
                        // This constructor has parameters - generate extraction
                        parameterExtractionStatements = 'g_array = elem(${innerExprStr}, 1)\n';
                        
                        #if debug_pattern_matching
//                         trace('[PatternMatchingCompiler] Generating parameter extraction for constructor index ${constructorIndex}');
                        #end
                    }
                }
                
                var body = compilePatternBody(caseData.expr, context);
                
                // Combine parameter extraction with case body
                var fullBody = if (parameterExtractionStatements.length > 0) {
                    '(\n${parameterExtractionStatements}${body}\n)';
                } else {
                    body;
                };
                
                caseStrings.push('  ${pattern} -> ${fullBody}');
                
                #if debug_pattern_matching
//                 trace('[PatternMatchingCompiler] Generated direct pattern: ${pattern} -> [body with extraction]');
                #end
            }
        }
        
        // Add default case if present
        if (defaultExpr != null) {
            var defaultBody = compilePatternBody(defaultExpr, context);
            caseStrings.push('  _ -> ${defaultBody}');
        }
        
        // Generate the standard case expression without elem() wrapping for direct enum switches
        var result = 'case ${innerExprStr} do\n${caseStrings.join("\n")}\nend';
        
        #if debug_pattern_matching
//         trace("[PatternMatchingCompiler] ✓ DIRECT TSwitch(TEnumIndex) COMPILATION END");
//         trace('[PatternMatchingCompiler] Generated clean case: ${result.substring(0, 100)}...');
        #end
        
        return result;
    }
    
    /**
     * Detect if a variable is used within an expression
     * 
     * WHY: We need to determine which pattern variables are actually used in case bodies
     * to properly prefix unused ones with underscore and avoid compilation warnings.
     * 
     * WHAT: Recursively traverses the AST to find TLocal references to a specific variable
     * 
     * HOW: Deep traversal checking all expression types that might contain variable references
     * 
     * @param expr The expression to search within
     * @param varName The variable name to search for
     * @return True if the variable is referenced anywhere in the expression
     */
    private function isVariableUsedInExpression(expr: TypedExpr, varName: String): Bool {
        if (expr == null) return false;
        
        return switch (expr.expr) {
            case TLocal(v):
                // Direct variable reference
                v.name == varName;
                
            case TVar(tvar, init):
                // Variable declaration - check initializer but not the variable itself
                (init != null && isVariableUsedInExpression(init, varName));
                
            case TBlock(el):
                // Block of expressions
                Lambda.exists(el, e -> isVariableUsedInExpression(e, varName));
                
            case TIf(econd, eif, eelse):
                // Conditional expression
                isVariableUsedInExpression(econd, varName) ||
                isVariableUsedInExpression(eif, varName) ||
                (eelse != null && isVariableUsedInExpression(eelse, varName));
                
            case TSwitch(e, cases, def):
                // Switch expression
                isVariableUsedInExpression(e, varName) ||
                Lambda.exists(cases, c -> Lambda.exists(c.values, v -> isVariableUsedInExpression(v, varName)) || 
                                          isVariableUsedInExpression(c.expr, varName)) ||
                (def != null && isVariableUsedInExpression(def, varName));
                
            case TCall(e, el):
                // Function call
                isVariableUsedInExpression(e, varName) ||
                Lambda.exists(el, arg -> isVariableUsedInExpression(arg, varName));
                
            case TField(e, _):
                // Field access
                isVariableUsedInExpression(e, varName);
                
            case TBinop(_, e1, e2):
                // Binary operation
                isVariableUsedInExpression(e1, varName) ||
                isVariableUsedInExpression(e2, varName);
                
            case TUnop(_, _, e):
                // Unary operation
                isVariableUsedInExpression(e, varName);
                
            case TParenthesis(e):
                // Parenthesized expression
                isVariableUsedInExpression(e, varName);
                
            case TReturn(e):
                // Return statement
                e != null && isVariableUsedInExpression(e, varName);
                
            case TArray(e1, e2):
                // Array access
                isVariableUsedInExpression(e1, varName) ||
                isVariableUsedInExpression(e2, varName);
                
            case TArrayDecl(el):
                // Array declaration
                Lambda.exists(el, e -> isVariableUsedInExpression(e, varName));
                
            case TObjectDecl(fields):
                // Object declaration
                Lambda.exists(fields, f -> isVariableUsedInExpression(f.expr, varName));
                
            case TFunction(f):
                // Function declaration - check body
                f.expr != null && isVariableUsedInExpression(f.expr, varName);
                
            case TCast(e, _):
                // Type cast
                isVariableUsedInExpression(e, varName);
                
            case TWhile(econd, e, _):
                // While loop
                isVariableUsedInExpression(econd, varName) ||
                isVariableUsedInExpression(e, varName);
                
            case TFor(_, iter, body):
                // For loop
                isVariableUsedInExpression(iter, varName) ||
                isVariableUsedInExpression(body, varName);
                
            case TTry(e, catches):
                // Try-catch
                isVariableUsedInExpression(e, varName) ||
                Lambda.exists(catches, c -> isVariableUsedInExpression(c.expr, varName));
                
            case TThrow(e):
                // Throw statement
                isVariableUsedInExpression(e, varName);
                
            case TMeta(_, e):
                // Meta expression
                isVariableUsedInExpression(e, varName);
                
            case _:
                // Other expressions don't contain variable references
                false;
        };
    }
    
    /**
     * Check if an expression contains TEnumParameter extraction
     * 
     * WHY: We need to detect if enum constructors have parameters, but construct.params.length
     *      sometimes returns 0 incorrectly. By checking if the case body uses TEnumParameter,
     *      we can reliably detect parameterized constructors.
     * 
     * @param expr The expression to check
     * @return True if the expression contains TEnumParameter
     */
    private function containsEnumParameter(expr: TypedExpr): Bool {
        var found = false;
        
        function checkExpr(e: TypedExpr): Void {
            if (found) return; // Early exit if already found
            
            switch (e.expr) {
                case TEnumParameter(_, _, _):
                    found = true;
                    
                case TBlock(el):
                    for (subExpr in el) {
                        checkExpr(subExpr);
                    }
                    
                case TVar(_, init) if (init != null):
                    checkExpr(init);
                    
                case TIf(cond, eif, eelse):
                    checkExpr(cond);
                    checkExpr(eif);
                    if (eelse != null) checkExpr(eelse);
                    
                case TSwitch(e, cases, def):
                    checkExpr(e);
                    for (c in cases) {
                        for (v in c.values) checkExpr(v);
                        checkExpr(c.expr);
                    }
                    if (def != null) checkExpr(def);
                    
                case TReturn(e) if (e != null):
                    checkExpr(e);
                    
                case TCall(e, args):
                    checkExpr(e);
                    for (arg in args) checkExpr(arg);
                    
                case TField(e, _):
                    checkExpr(e);
                    
                case TBinop(_, e1, e2):
                    checkExpr(e1);
                    checkExpr(e2);
                    
                case TUnop(_, _, e):
                    checkExpr(e);
                    
                case TParenthesis(e):
                    checkExpr(e);
                    
                case _:
                    // Other expression types don't contain TEnumParameter
            }
        }
        
        checkExpr(expr);
        return found;
    }
    
    /**
     * Find variables that are actually used in a case body expression
     * 
     * WHY: Enum pattern matching generates TEnumParameter extractions even when parameters 
     *      are never used in the case body. This causes orphaned variables like g_array.
     * 
     * WHAT: Recursively analyze a TypedExpr AST to find all TLocal variable references.
     *       Build a map of variable names that are actually referenced in the expression tree.
     * 
     * HOW: Traverse the entire AST using pattern matching on TypedExprDef variants.
     *      For each TLocal, mark the variable name as used.
     *      Recurse into all sub-expressions to ensure complete coverage.
     * 
     * @param expr The case body expression to analyze
     * @return Map of variable names to boolean (true = used)
     */
    public function findUsedVariables(expr: TypedExpr): Map<String, Bool> {
        var usedVars = new Map<String, Bool>();
        
        #if debug_pattern_matching
        // trace('[XRay PatternMatchingCompiler] FINDING USED VARIABLES in expression type: ${Type.enumConstructor(expr.expr)}');
        #end
        
        function analyzeExpression(e: TypedExpr): Void {
            switch (e.expr) {
                case TLocal(v):
                    // Direct variable reference - mark as used
                    usedVars.set(v.name, true);
                    #if debug_pattern_matching
                    // trace('[XRay PatternMatchingCompiler] ✓ Found variable usage: ${v.name}');
                    #end
                    
                case TBlock(expressions):
                    // Analyze all expressions in block
                    for (subExpr in expressions) {
                        analyzeExpression(subExpr);
                    }
                    
                case TBinop(op, e1, e2):
                    // Analyze both sides of binary operation
                    analyzeExpression(e1);
                    analyzeExpression(e2);
                    
                case TUnop(op, postFix, subExpr):
                    // Analyze unary operation expression
                    analyzeExpression(subExpr);
                    
                case TCall(func, args):
                    // Analyze function and all arguments
                    analyzeExpression(func);
                    for (arg in args) {
                        analyzeExpression(arg);
                    }
                    
                case TField(subExpr, field):
                    // Analyze field access expression
                    analyzeExpression(subExpr);
                    
                case TIf(cond, ifExpr, elseExpr):
                    // Analyze condition and both branches
                    analyzeExpression(cond);
                    analyzeExpression(ifExpr);
                    if (elseExpr != null) {
                        analyzeExpression(elseExpr);
                    }
                    
                case TSwitch(switchExpr, cases, defaultExpr):
                    // Analyze switch expression, all cases, and default
                    analyzeExpression(switchExpr);
                    for (caseData in cases) {
                        for (value in caseData.values) {
                            analyzeExpression(value);
                        }
                        analyzeExpression(caseData.expr);
                    }
                    if (defaultExpr != null) {
                        analyzeExpression(defaultExpr);
                    }
                    
                case TReturn(subExpr):
                    // Analyze return expression
                    if (subExpr != null) {
                        analyzeExpression(subExpr);
                    }
                    
                case TVar(v, initExpr):
                    // Analyze variable initialization
                    if (initExpr != null) {
                        analyzeExpression(initExpr);
                    }
                    
                case TArrayDecl(elements):
                    // Analyze all array elements
                    for (element in elements) {
                        analyzeExpression(element);
                    }
                    
                case TObjectDecl(fields):
                    // Analyze all object field values
                    for (field in fields) {
                        analyzeExpression(field.expr);
                    }
                    
                case TParenthesis(subExpr):
                    // Analyze parenthesized expression
                    analyzeExpression(subExpr);
                    
                case TMeta(meta, subExpr):
                    // Analyze meta expression
                    analyzeExpression(subExpr);
                    
                case TCast(subExpr, type):
                    // Analyze cast expression
                    analyzeExpression(subExpr);
                    
                case TWhile(cond, body, normalWhile):
                    // Analyze while condition and body
                    analyzeExpression(cond);
                    analyzeExpression(body);
                    
                case TFor(v, iterator, body):
                    // Analyze iterator and loop body
                    analyzeExpression(iterator);
                    analyzeExpression(body);
                    
                case TTry(tryExpr, catches):
                    // Analyze try expression and catch blocks
                    analyzeExpression(tryExpr);
                    for (catchData in catches) {
                        analyzeExpression(catchData.expr);
                    }
                    
                case TEnumParameter(enumExpr, ef, index):
                    // Analyze enum parameter expression
                    analyzeExpression(enumExpr);
                    
                case TEnumIndex(enumExpr):
                    // Analyze enum index expression
                    analyzeExpression(enumExpr);
                    
                // Leaf expressions - no sub-expressions to analyze
                case TConst(_):
                case TTypeExpr(_):
                case TFunction(_):
                
                // Other expressions - analyze recursively if they have sub-expressions
                case _:
                    #if debug_pattern_matching
                    // trace('[XRay PatternMatchingCompiler] ⚠️ Unhandled expression type in usage analysis: ${Type.enumConstructor(e.expr)}');
                    #end
            }
        }
        
        // Start analysis from root expression
        analyzeExpression(expr);
        
        #if debug_pattern_matching
        var varNames = [for (name in usedVars.keys()) name];
        // trace('[XRay PatternMatchingCompiler] Used variables found: [${varNames.join(", ")}]');
        #end
        
        return usedVars;
    }
    
    /**
     * Detect if a switch expression is based on elem() call
     * 
     * WHY: elem() based switches need integer patterns, not tuple patterns
     * WHAT: Check if the switch expression contains elem(expr, 0) pattern
     * HOW: Analyze the TypedExpr AST for TCall with elem field access
     * 
     * @param switchExpr The switch expression to analyze
     * @return True if this is an elem() based switch
     */
    private function detectElemBasedSwitch(switchExpr: TypedExpr): Bool {
        #if debug_pattern_matching
        // trace('[XRay PatternMatchingCompiler] detectElemBasedSwitch: analyzing ${switchExpr.expr}');
        #end
        
        return switch (switchExpr.expr) {
            case TCall(e, args):
                // Check if this is a call to elem()
                switch (e.expr) {
                    case TField(_, FStatic(_, cf)) if (cf.get().name == "elem"):
                        #if debug_pattern_matching
                        // trace('[XRay PatternMatchingCompiler] ✓ Found elem() call - this is elem() based switch');
                        #end
                        true;
                    case TField(_, FEnum(_, _)):
                        // This is enum constructor call, not elem()
                        #if debug_pattern_matching
                        // trace('[XRay PatternMatchingCompiler] Found enum constructor call - this is direct enum switch');
                        #end
                        false;
                    case _:
                        #if debug_pattern_matching
                        // trace('[XRay PatternMatchingCompiler] Call to non-elem function');
                        #end
                        false;
                }
            case TLocal(_):
                // Local variable - could be either type, assume direct enum
                #if debug_pattern_matching
                // trace('[XRay PatternMatchingCompiler] Local variable - assuming direct enum switch');
                #end
                false;
            case _:
                #if debug_pattern_matching
                // trace('[XRay PatternMatchingCompiler] Other expression type - assuming direct enum switch');
                #end
                false;
        };
    }
    
    /**
     * Check if the current switch is elem() based
     * 
     * @return True if current switch uses elem() patterns
     */
    private function isElemBasedSwitch(): Bool {
        return currentSwitchIsElemBased;
    }
    
    /**
     * Compile enum switch using index-based matching
     * 
     * WHY: Enum switches like switch(spec) with case PubSub(name) need to compile to
     *      case(elem(spec, 0)) do 0 -> with proper parameter extraction
     * 
     * WHAT: Converts direct enum destructuring to index-based matching patterns
     * 
     * HOW: Generate case(elem(switchExpr, 0)) do with integer patterns and 
     *      proper enum parameter extraction in case bodies
     * 
     * @param switchExpr The enum expression being switched on
     * @param cases Array of case patterns and expressions  
     * @param defaultExpr Optional default case expression
     * @param context Optional function context for field assignment transformation
     * @param enumType The enum type information
     * @return Generated Elixir case statement with index patterns
     */
    private function compileEnumIndexSwitch(
        switchExpr: TypedExpr,
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>,
        defaultExpr: Null<TypedExpr>,
        ?context: FunctionContext,
        ?enumType: EnumType
    ): String {
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] ✓ ENUM INDEX SWITCH COMPILATION START');
//         trace('[PatternMatchingCompiler] Enum type: ${enumType != null ? enumType.name : "null"}');
//         trace('[PatternMatchingCompiler] Cases: ${cases.length}');
        #end
        
        /**
         * DEFINITIVE FIX: Compile switch expression and extract variable name
         * 
         * WHY: When switching on function calls like Type.typeof(), the compiler
         *      generates assignments like 'g_array = Type.typeof(value)' due to
         *      TVar.id mappings. We must extract the assigned variable name.
         * 
         * WHAT: Compile the expression and parse any assignment to get the
         *       actual variable name for use in case statements.
         * 
         * HOW: Use regex to detect 'variable = expression' pattern and extract
         *      the variable. This ensures case uses the same variable as assignment.
         */
        var compiledExpr = compiler.compileExpression(switchExpr);
        var switchVarStr = compiledExpr;
        
        // Check if this is an assignment and extract the variable
        var assignmentPattern = ~/^([a-z_][a-zA-Z0-9_]*) = /;
        if (assignmentPattern.match(compiledExpr)) {
            switchVarStr = assignmentPattern.matched(1);
            #if debug_pattern_matching
//             trace('[compileEnumIndexSwitch] ✓ EXTRACTED VARIABLE FROM ASSIGNMENT');
//             trace('[compileEnumIndexSwitch] Full expression: ${compiledExpr}');
//             trace('[compileEnumIndexSwitch] Variable for switch: ${switchVarStr}');
            #end
        }
        
        // CRITICAL FIX: Check if this enum has parameters to determine pattern type
        // Atom-only enums should use direct pattern matching, not elem() extraction
        var hasParameters = false;
        var constructorHasParams = new Map<Int, Bool>(); 
        
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] Analyzing enum ${enumType != null ? enumType.name : "unknown"} for parameter usage');
        #end
        
        // Analyze case bodies to detect if they extract enum parameters
        if (enumType != null) {
            for (i in 0...cases.length) {
                var caseData = cases[i];
                // Check if the case body contains TEnumParameter expressions
                var usesEnumParams = containsEnumParameter(caseData.expr);
                if (usesEnumParams) {
                    hasParameters = true;
                    for (value in caseData.values) {
                        switch (value.expr) {
                            case TConst(TInt(index)):
                                constructorHasParams.set(index, true);
                                #if debug_pattern_matching
//                                 trace('[PatternMatchingCompiler] Constructor at index ${index} uses parameters (found TEnumParameter in body)');
                                #end
                            case _:
                        }
                    }
                }
            }
        }
        
        #if debug_pattern_matching  
//         trace('[PatternMatchingCompiler] Enum has parameters: ${hasParameters}');
        #end
        
        // Generate appropriate switch expression based on enum type
        var exprStr: String;
        if (hasParameters) {
            // Tuple-based enum: Use elem() to extract constructor index  
            currentSwitchIsElemBased = true;
            exprStr = 'elem(${switchVarStr}, 0)';
            #if debug_pattern_matching
//             trace('[PatternMatchingCompiler] Using elem() extraction for tuple-based enum');
            #end
        } else {
            // Atom-only enum: Use direct pattern matching on atoms
            currentSwitchIsElemBased = false;
            exprStr = switchVarStr;
            #if debug_pattern_matching
//             trace('[PatternMatchingCompiler] Using direct atom matching for atom-only enum');
            #end
        }
        
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] Switch expression: ${exprStr}');
        #end
        
        var caseStrings: Array<String> = [];
        
        // Build index mapping for enum constructors
        var enumConstructors = [];
        if (enumType != null) {
            for (name in enumType.names) {
                enumConstructors.push(name);
            }
        }
        
        for (caseData in cases) {
            #if debug_pattern_matching
//             trace('[PatternMatchingCompiler] Processing case with ${caseData.values.length} values');
            #end
            
            // Extract pattern variables from the case VALUE (the pattern) not the body
            // For cases like Legacy(spec), we need to find what spec was renamed to
            var patternVars = new Map<Int, String>();
            
            // Look at the actual pattern to find variable names
            for (value in caseData.values) {
                switch (value.expr) {
                    case TCall(e, args):
                        // This is an enum constructor pattern like Legacy(spec)
                        for (i in 0...args.length) {
                            switch (args[i].expr) {
                                case TLocal(v):
                                    // Found a pattern variable - register the mapping!
                                    var varName = NamingHelper.toSnakeCase(v.name);
                                    var targetName = varName; // Default: use the actual name
                                    
                                    // CRITICAL: Check for -reflaxe.renamed metadata to get original name
                                    if (v.meta != null && v.meta.has("-reflaxe.renamed")) {
                                        var metaParams = v.meta.extract("-reflaxe.renamed")[0].params;
                                        if (metaParams != null && metaParams.length > 0) {
                                            switch (metaParams[0].expr) {
                                                case EConst(CString(origName)):
                                                    targetName = NamingHelper.toSnakeCase(origName);
                                                    #if debug_pattern_matching
//                                                     trace('[PatternMatchingCompiler] METADATA: Variable "${v.name}" has -reflaxe.renamed="${origName}", using "${targetName}"');
                                                    #end
                                                case _:
                                            }
                                        }
                                    } else if (~/^(.+?)([0-9]+)$/.match(varName)) {
                                        // Fallback: String-based detection if no metadata
                                        targetName = ~/^(.+?)([0-9]+)$/.replace(varName, "$1");
                                        #if debug_pattern_matching
//                                         trace('[PatternMatchingCompiler] FALLBACK: Detected renamed "${v.name}" → "${targetName}" via pattern');
                                        #end
                                    }
                                    
                                    // CRITICAL FIX: Check if variable is marked as unused and needs underscore prefix
                                    var isUnused = v.meta != null && v.meta.has("-reflaxe.unused");
                                    var finalName = if (isUnused && !StringTools.startsWith(targetName, "_")) {
                                        "_" + targetName;
                                    } else {
                                        targetName;
                                    }
                                    
                                    // Store the final name (with underscore if unused)
                                    patternVars.set(i, finalName);
                                    
                                    // Register TVar.id mapping so body references work
                                    if (compiler.variableCompiler != null) {
                                        compiler.variableCompiler.registerVariableMapping(v, finalName);
                                        #if debug_pattern_matching
//                                         trace('[PatternMatchingCompiler] ✓ REGISTERED TVAR MAPPING: ${v.name}(id:${v.id}) -> ${finalName}');
                                        #end
                                    }
                                    
                                    #if debug_pattern_matching
//                                     trace('[PatternMatchingCompiler] Found pattern variable from VALUE: index ${i} -> ${v.name}');
                                    #end
                                case _:
                            }
                        }
                    case _:
                }
            }
            
            // If no pattern variables found in values, check the body for TEnumParameter
            if (Lambda.count(patternVars) == 0) {
                patternVars = extractPatternVariables(caseData.expr);
            }
            
            for (value in caseData.values) {
                var pattern = null;
                var caseIndex = -1;
                
                #if debug_pattern_matching
//                 trace('[PatternMatchingCompiler] Processing case value: ${value.expr}');
                #end
                
                // Determine the enum constructor index
                switch (value.expr) {
                    case TCall(e, args):
                        #if debug_pattern_matching
//                         trace('[PatternMatchingCompiler] TCall with ${args.length} args');
                        for (i in 0...args.length) {
//                             trace('[PatternMatchingCompiler] Arg ${i}: ${args[i].expr}');
                        }
                        #end
                        switch (e.expr) {
                            case TField(_, FEnum(enumRef, enumField)):
                                caseIndex = enumConstructors.indexOf(enumField.name);
                                #if debug_pattern_matching
//                                 trace('[PatternMatchingCompiler] Found enum constructor ${enumField.name} at index ${caseIndex}');
                                #end
                            case _:
                                #if debug_pattern_matching
//                                 trace('[PatternMatchingCompiler] TCall with non-enum field');
                                #end
                        }
                    case TConst(TInt(n)):
                        caseIndex = n;
                        #if debug_pattern_matching
//                         trace('[PatternMatchingCompiler] Found integer pattern ${n}');
                        #end
                    case _:
                        #if debug_pattern_matching
//                         trace('[PatternMatchingCompiler] Other pattern type: ${value.expr}');
                        #end
                }
                
                if (caseIndex >= 0) {
                    /**
                     * CRITICAL FIX: Enum Pattern Generation for Atom vs Tuple Enums
                     * 
                     * WHY: Elixir represents enums differently based on whether constructors have parameters:
                     * - Atom-only enums → :atom_name (memory efficient, no data payload)
                     * - Tuple-based enums → {:atom_name, data...} (carries parameter data)
                     * The pattern matching MUST align with this representation to avoid runtime errors.
                     * 
                     * WHAT: Generate appropriate Elixir patterns based on enum structure:
                     * - hasParameters=true: Integer patterns (0, 1, 2) for elem(tuple, 0) matching
                     * - hasParameters=false: Atom patterns (:todo_updates, :user_activity) for direct matching
                     * 
                     * HOW: Check hasParameters flag and generate patterns accordingly:
                     * 1. Tuple enums: Use integer patterns that match elem() extraction results
                     * 2. Atom enums: Convert constructor names to snake_case atoms
                     * 3. Apply NamingHelper for consistent Elixir naming conventions
                     * 
                     * CRITICAL FIX: Handle pattern variables for enum constructors
                     * When we have pattern variables (e.g., Legacy(spec)), we need to generate tuple patterns
                     * with the variable names: {6, spec} instead of just 6.
                     */
                    if (hasParameters) {
                        // Check if we have pattern variables for this case (e.g., Legacy(spec))
                        // These are extracted from the TCall arguments in the pattern
                        if (Lambda.count(patternVars) > 0) {
                            // Generate tuple pattern with variables: {index, var1, var2, ...}
                            var tupleElements = [Std.string(caseIndex)];
                            
                            // Add each pattern variable to the tuple
                            for (i in 0...Lambda.count(patternVars)) {
                                if (patternVars.exists(i)) {
                                    var varName = patternVars.get(i);
                                    
                                    // CRITICAL FIX: Use the variable name as registered (includes underscore prefix if unused)
                                    // The patternVars map already contains the correct name with underscore if needed
                                    // We should NOT strip suffixes or modify it further here
                                    tupleElements.push(varName);
                                    
                                    #if debug_pattern_matching
//                                     trace('[PatternMatchingCompiler] Using registered variable name in pattern: ${varName}');
                                    #end
                                } else {
                                    // Placeholder for missing pattern variable
                                    tupleElements.push("_");
                                }
                            }
                            
                            // Generate tuple pattern: {6, spec} or {6, spec, other_var}
                            pattern = '{${tupleElements.join(", ")}}';
                            
                            #if debug_pattern_matching
//                             trace('[PatternMatchingCompiler] Generated tuple pattern with variables: ${pattern}');
                            #end
                        } else {
                            // No pattern variables - use simple integer pattern
                            pattern = Std.string(caseIndex);
                            #if debug_pattern_matching
//                             trace('[PatternMatchingCompiler] Generated integer pattern: ${pattern}');
                            #end
                        }
                    } else {
                        // Atom-only enum: Use atom patterns for direct matching
                        if (enumType != null && caseIndex < enumType.names.length) {
                            var constructorName = enumType.names[caseIndex];
                            var atomName = NamingHelper.toSnakeCase(constructorName);
                            pattern = ':${atomName}';
                            #if debug_pattern_matching
//                             trace('[PatternMatchingCompiler] Generated atom pattern: ${pattern}');
                            #end
                        } else {
                            pattern = "_"; // Fallback for invalid index
                        }
                    }
                }
                
                if (pattern != null) {
                    // Set up pattern usage context for enum parameter extraction
                    var usedVariables = findUsedVariables(caseData.expr);
                    compiler.patternUsageContext = usedVariables;
                    compiler.currentSwitchCaseBody = caseData.expr;
                    
                    // Check if we need to generate parameter extraction for this enum constructor
                    var parameterExtraction = "";
                    if (enumType != null && caseIndex >= 0 && caseIndex < enumType.names.length) {
                        var constructorName = enumType.names[caseIndex];
                        var constructor = enumType.constructs.get(constructorName);
                        
                        // Check if this constructor has parameters from the original pattern
                        // Look for TCall patterns in the case value to detect parameters
                        var hasParameters = false;
                        var paramNames: Array<String> = [];
                        
                        // We already extracted pattern variables above, just check if this constructor has parameters
                        switch (value.expr) {
                            case TCall(e, args):
                                if (args.length > 0) {
                                    hasParameters = true;
                                    // Build param names from what we already extracted
                                    for (i in 0...args.length) {
                                        if (patternVars.exists(i)) {
                                            paramNames.push(patternVars.get(i));
                                        } else {
                                            // Fallback for complex patterns
                                            paramNames.push("g_array");
                                        }
                                    }
                                }
                            case _:
                        }
                        
                        // Generate parameter extraction if needed
                        if (hasParameters && paramNames.length > 0) {
                            // Check if we have a pattern variable from the body (like spec2)
                            if (patternVars.exists(0)) {
                                var extractedVarName = patternVars.get(0);
                                // The pattern has the renamed variable (spec2)
                                // But the body uses the original name (spec)
                                // So we extract to the original name directly
                                // Check if this looks like a renamed variable
                                if (~/^(.+?)([0-9]+)$/.match(extractedVarName)) {
                                    // Extract base name without number suffix
                                    var originalName = ~/^(.+?)([0-9]+)$/.replace(extractedVarName, "$1");
                                    // Extract directly to the original name that the body uses
                                    parameterExtraction = '${originalName} = elem(${switchVarStr}, 1)\n    ';
                                    #if debug_pattern_matching
//                                     trace('[PatternMatchingCompiler] Extracted to original name: ${originalName} (pattern had ${extractedVarName})');
                                    #end
                                } else {
                                    // No renaming detected, use as-is
                                    parameterExtraction = '${extractedVarName} = elem(${switchVarStr}, 1)\n    ';
                                }
                            } else {
                                // No pattern variable found in body, use default extraction
                                var uniqueVarName = enumNestingLevel <= 1 ? "g_array" : 'g_array${enumNestingLevel}';
                                parameterExtraction = '${uniqueVarName} = elem(${switchVarStr}, 1)\n    ';
                            }
                            
                            #if debug_pattern_matching
//                             trace('[PatternMatchingCompiler] Generated parameter extraction: ${parameterExtraction}');
                            #end
                        }
                    }
                    
                    // Compile case body with pattern variable extraction
                    var body = compilePatternBody(caseData.expr, context);
                    
                    // Clear context
                    compiler.patternUsageContext = null;
                    compiler.currentSwitchCaseBody = null;
                    
                    // CRITICAL FIX: Check if extracted variable is actually used before generating extraction
                    // When pattern variables are bound directly in the pattern, we don't need elem() extraction
                    var shouldGenerateExtraction = parameterExtraction.length > 0;
                    
                    // If we bound variables in the pattern (e.g., {6, spec2}), don't extract
                    if (patternVars.exists(0) && pattern.contains(patternVars.get(0))) {
                        parameterExtraction = "";
                        shouldGenerateExtraction = false;
                        
                        // Check if we need an alias for renamed variables
                        var varName = patternVars.get(0);
                        if (~/^(.+?)([0-9]+)$/.match(varName)) {
                            // Extract base name without number suffix  
                            var baseName = ~/^(.+?)([0-9]+)$/.replace(varName, "$1");
                            if (body.contains(baseName) && !body.contains(varName)) {
                                // Body uses original name but pattern has renamed version
                                parameterExtraction = '${baseName} = ${varName}\n    ';
                                shouldGenerateExtraction = true;
                                #if debug_pattern_matching
//                                 trace('[PatternMatchingCompiler] Created alias: ${baseName} = ${varName}');
                                #end
                            }
                        }
                    } else if (shouldGenerateExtraction) {
                        var uniqueVarName = enumNestingLevel <= 1 ? "g_array" : 'g_array${enumNestingLevel}';
                        
                        // Check if the extracted variable name appears in the compiled body
                        if (!body.contains(uniqueVarName)) {
                            // Variable is not used, skip extraction to avoid orphaned variables
                            parameterExtraction = "";
                            shouldGenerateExtraction = false;
                            
                            #if debug_pattern_matching
//                             trace('[PatternMatchingCompiler] ✓ SKIPPED ORPHANED EXTRACTION: ${uniqueVarName} not used in body');
                            #end
                        }
                    }
                    
                    // Combine parameter extraction with body
                    var fullBody = if (shouldGenerateExtraction) {
                        '(\n    ${parameterExtraction}${body}\n  )';
                    } else {
                        body;
                    };
                    
                    caseStrings.push('  ${pattern} ->\n    ${fullBody}');
                }
            }
        }
        
        if (defaultExpr != null) {
            var defaultBody = compilePatternBody(defaultExpr, context);
            caseStrings.push('  _ -> ${defaultBody}');
        }
        
        // Reset the elem() based flag
        currentSwitchIsElemBased = false;
        
        var result = 'case (${exprStr}) do\n${caseStrings.join("\n")}\nend';
        
        #if debug_pattern_matching
//         trace('[PatternMatchingCompiler] ✓ ENUM INDEX SWITCH COMPILATION END');
//         trace('[PatternMatchingCompiler] Result: ${result.substring(0, 200)}...');
        #end
        
        return result;
    }
}

#end