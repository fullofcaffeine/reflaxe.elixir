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
        ?context: reflaxe.elixir.helpers.ControlFlowCompiler.FunctionContext
    ): String {
        
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
        
        #if debug_temp_var
        trace("[PatternMatchingCompiler] ============== SWITCH COMPILATION START ==============");
        trace('[PatternMatchingCompiler] compileSwitchExpression called');
        trace('[PatternMatchingCompiler] Switch expr type: ${switchExpr.expr}');
        trace('[PatternMatchingCompiler] Switch expr t type: ${switchExpr.t}');
        trace('[PatternMatchingCompiler] Number of cases: ${cases.length}');
        trace('[PatternMatchingCompiler] Has default: ${defaultExpr != null}');
        #end
        
        // Check for temp variable assignment patterns in all cases
        for (i in 0...cases.length) {
            var caseData = cases[i];
            
            #if debug_temp_var
            trace('[PatternMatchingCompiler] Case ${i}: ${caseData.values.length} values');
            for (v in caseData.values) {
                trace('[PatternMatchingCompiler]   Value: ${v.expr}');
            }
            #end
            
            // Check case body for temp variable patterns
            switch (caseData.expr.expr) {
                case TBinop(OpAssign, left, right):
                    switch (left.expr) {
                        case TLocal(v):
                            var varName = compiler.getOriginalVarName(v);
                            #if debug_temp_var
                            trace('[PatternMatchingCompiler]   Case body assigns to: ${varName}');
                            #end
                            
                            if (varName.indexOf("temp") == 0) {
                                if (tempVarName == null) {
                                    tempVarName = varName;
                                    #if debug_temp_var
                                    trace('[PatternMatchingCompiler]   ✓ TEMP VARIABLE ASSIGNMENT DETECTED: ${tempVarName}');
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
                            trace('[PatternMatchingCompiler]   Case body assigns to non-local');
                            #end
                    }
                case _:
                    allCasesAssignToTempVar = false;
                    #if debug_temp_var
                    trace('[PatternMatchingCompiler]   Case body type: ${caseData.expr.expr}');
                    #end
            }
        }
        
        // If all cases assign to the same temp variable, transform them
        if (allCasesAssignToTempVar && tempVarName != null) {
            #if debug_temp_var
            trace('[PatternMatchingCompiler] ✓ ALL CASES ASSIGN TO TEMP VARIABLE: ${tempVarName}');
            trace('[PatternMatchingCompiler] Transforming to direct value returns...');
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
            trace('[PatternMatchingCompiler] ✓ TRANSFORMATION COMPLETE');
            #end
        }
        
        #if debug_temp_var
        trace("[PatternMatchingCompiler] ============== SWITCH COMPILATION END ==============");
        #end
        
        
        #if debug_pattern_matching
        trace("[PatternMatchingCompiler] Compiling switch expression");
        trace('[PatternMatchingCompiler] Switch expr type: ${switchExpr.t}');
        trace('[PatternMatchingCompiler] Number of cases: ${cases.length}');
        #end
        
        // CRITICAL FIX: Detect TSwitch(TEnumIndex(expr)) pattern for direct Result/Option compilation
        // This prevents double-nested case expressions by bypassing EnumIntrospectionCompiler
        if (isSwitchOnEnumIndex(switchExpr)) {
            #if debug_pattern_matching
            trace("[PatternMatchingCompiler] ✓ DETECTED TSwitch(TEnumIndex) - direct compilation");
            #end
            return compileSwitchOnEnumIndexDirectly(switchExpr, cases, defaultExpr, context);
        }
        
        // Check if this is a with statement pattern
        if (shouldUseWithStatement(switchExpr, cases)) {
            #if debug_pattern_matching
            trace("[PatternMatchingCompiler] Using with statement optimization");
            #end
            return compileWithStatement(switchExpr, cases, defaultExpr, context);
        }
        
        // Check for enum type handling
        var enumType = extractEnumType(switchExpr.t);
        
        
        if (enumType != null) {
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] ✓ DETECTED ENUM TYPE: ${enumType.name}');
            #end
            
            // Special handling for Option and Result types
            if (isOptionType(enumType)) {
                #if debug_pattern_matching
                trace('[PatternMatchingCompiler] → Using Option switch compilation');
                #end
                return compileOptionSwitch(switchExpr, cases, defaultExpr, context);
            } else if (isResultType(enumType)) {
                #if debug_pattern_matching
                trace('[PatternMatchingCompiler] → Using Result switch compilation');
                #end
                return compileResultSwitch(switchExpr, cases, defaultExpr, context);
            } else {
                // CRITICAL FIX: Handle all other enum types with index-based matching
                // Convert switch(enum) to case(elem(enum, 0)) with integer patterns
                #if debug_pattern_matching
                trace('[PatternMatchingCompiler] → USING INDEX-BASED MATCHING FOR ENUM: ${enumType.name}');
                trace('[PatternMatchingCompiler] → Calling compileEnumIndexSwitch...');
                #end
                return compileEnumIndexSwitch(switchExpr, cases, defaultExpr, context, enumType);
            }
        } else {
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] ⚠️ NO ENUM TYPE DETECTED - using standard case compilation');
            #end
            
            // CRITICAL FIX: Try to detect enum type from switch cases themselves
            // Sometimes enum type isn't detected from switch expr but we can detect it from patterns
            var inferredEnumType = inferEnumTypeFromCases(cases);
            if (inferredEnumType != null) {
                #if debug_pattern_matching
                trace('[PatternMatchingCompiler] ✓ INFERRED ENUM TYPE: ${inferredEnumType.name} - forcing elem-based compilation');
                #end
                return compileEnumIndexSwitch(switchExpr, cases, defaultExpr, context, inferredEnumType);
            }
            
            // CRITICAL FIX: Force ALL switches to use elem-based compilation by default
            // This ensures consistent pattern generation across all enum switches
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] ✓ FORCING ALL SWITCHES TO USE ELEM-BASED COMPILATION');
            #end
            return compileEnumIndexSwitch(switchExpr, cases, defaultExpr, context, null);
        }
        
        // Standard case statement compilation
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
        ?context: reflaxe.elixir.helpers.ControlFlowCompiler.FunctionContext
    ): String {
        
        // CRITICAL FIX: Remove 'g' mapping before compiling switch expression
        // The 'g' variable should never be mapped to g_counter in switch expressions
        var savedGMapping: Null<String> = null;
        if (compiler.currentFunctionParameterMap.exists("g")) {
            savedGMapping = compiler.currentFunctionParameterMap.get("g");
            compiler.currentFunctionParameterMap.remove("g");
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] Temporarily removed g mapping in with statement: g -> ${savedGMapping}');
            #end
        }
        
        var exprStr = compiler.compileExpression(switchExpr);
        
        // Restore the 'g' mapping after compilation
        // CRITICAL FIX: Don't restore if the mapping is to g_counter - that's always wrong
        if (savedGMapping != null && !StringTools.endsWith(savedGMapping, "_counter")) {
            compiler.currentFunctionParameterMap.set("g", savedGMapping);
        } else if (savedGMapping != null) {
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] ⚠️ BLOCKED restoration of incorrect g -> ${savedGMapping} mapping');
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
        trace('[PatternMatchingCompiler] Compiling Result pattern: ${enumField.name}');
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
        trace('[PatternMatchingCompiler] Generated Result pattern: ${patternStr}');
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
        trace('[PatternMatchingCompiler] Compiling Option pattern: ${enumField.name}');
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
        trace('[PatternMatchingCompiler] Generated Option pattern: ${patternStr}');
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
                // Pattern variable
                NamingHelper.toSnakeCase(v.name);
                
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
                            trace('[inferEnumTypeFromCases] Detected enum type: ${enumType.name}');
                            trace('[inferEnumTypeFromCases] From constructor: ${ef.name}');
                            #end
                            return enumType;
                        }
                        
                    default:
                        // Continue checking other patterns
                }
            }
        }
        
        #if debug_pattern_matching
        trace('[inferEnumTypeFromCases] No enum type detected from case patterns');
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
        ?context: reflaxe.elixir.helpers.ControlFlowCompiler.FunctionContext
    ): String {
        
        // CRITICAL FIX: Detect if this is an elem() based switch
        // This determines whether patterns should be integers or tuples
        currentSwitchIsElemBased = detectElemBasedSwitch(switchExpr);
        
        
        // CRITICAL FIX: Remove 'g' mapping before compiling switch expression
        // The 'g' variable should never be mapped to g_counter in switch expressions
        var savedGMapping: Null<String> = null;
        if (compiler.currentFunctionParameterMap.exists("g")) {
            savedGMapping = compiler.currentFunctionParameterMap.get("g");
            compiler.currentFunctionParameterMap.remove("g");
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] Temporarily removed g mapping in standard case: g -> ${savedGMapping}');
            #end
        }
        
        var exprStr = compiler.compileExpression(switchExpr);
        
        // Restore the 'g' mapping after compilation
        // CRITICAL FIX: Don't restore if the mapping is to g_counter - that's always wrong
        if (savedGMapping != null && !StringTools.endsWith(savedGMapping, "_counter")) {
            compiler.currentFunctionParameterMap.set("g", savedGMapping);
        } else if (savedGMapping != null) {
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] ⚠️ BLOCKED restoration of incorrect g -> ${savedGMapping} mapping');
            #end
        }
        var caseStrings: Array<String> = [];
        
        for (caseData in cases) {
            #if debug_pattern_matching
            trace("\n[XRay PatternMatchingCompiler] ========== PROCESSING NEW CASE ==========");
            trace('[XRay PatternMatchingCompiler] Case values count: ${caseData.values.length}');
            for (i in 0...caseData.values.length) {
                trace('[XRay PatternMatchingCompiler] Case value ${i}: ${caseData.values[i].expr}');
            }
            trace('[XRay PatternMatchingCompiler] Case body type: ${caseData.expr.expr}');
            #end
            
            // Extract pattern variables from the case body first
            var patternVars = extractPatternVariables(caseData.expr);
            
            #if debug_pattern_matching
            trace('[XRay PatternMatchingCompiler] Pattern variables extracted: ${Lambda.count(patternVars)} vars');
            for (idx in patternVars.keys()) {
                trace('[XRay PatternMatchingCompiler]   Index ${idx}: ${patternVars.get(idx)}');
            }
            #end
            
            // Compile patterns with extracted variables
            var patterns = [];
            for (value in caseData.values) {
                patterns.push(compilePatternWithVariables(value, patternVars));
            }
            
            #if debug_pattern_matching
            trace('[XRay PatternMatchingCompiler] Generated patterns: ${patterns}');
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
            trace('[XRay PatternMatchingCompiler] PATTERN USAGE ANALYSIS complete');
            trace('[XRay PatternMatchingCompiler] Used variables in case body: [${usedVarNames.join(", ")}]');
            trace('[XRay PatternMatchingCompiler] Context set for enum parameter optimization');
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
            trace('[XRay PatternMatchingCompiler] =====================================');
            trace('[XRay PatternMatchingCompiler] ✓ SET switch case body context for orphaned parameter detection');
            trace('[XRay PatternMatchingCompiler] Case body type: ${Type.enumConstructor(caseData.expr.expr)}');
            trace('[XRay PatternMatchingCompiler] Case values count: ${caseData.values.length}');
            trace('[XRay PatternMatchingCompiler] CONTEXT NOW AVAILABLE for enum parameter detection');
            trace('[XRay PatternMatchingCompiler] =====================================');
            #end
            
            // No changes needed here - the fix should be in EnumIntrospectionCompiler itself
            var savedGMapping = null;
            
            // Check if the body is a TBlock and pass context for field assignment transformation
            var body = switch (caseData.expr.expr) {
                case TBlock(el):
                    #if debug_state_threading
                    trace('[XRay compileStandardCase] TBlock case body with ${el.length} expressions');
                    trace('[XRay compileStandardCase] Context: ${context != null ? "exists" : "null"}');
                    if (context != null) {
                        trace('[XRay compileStandardCase] structParamName: ${context.structParamName}');
                    }
                    #end
                    // Filter out the TVar expressions used for pattern extraction
                    // Pass the pattern variables to the filter so it knows which extractions to keep
                    var filteredEl = filterPatternExtractionVars(el, patternVars);
                    // Pass context to ControlFlowCompiler for _this replacement
                    compiler.expressionDispatcher.controlFlowCompiler.compileBlock(filteredEl, false, context);
                default:
                    #if debug_state_threading
                    trace('[XRay compileStandardCase] Non-TBlock case body: ${caseData.expr.expr}');
                    trace('[XRay compileStandardCase] Expression type: ${Type.enumConstructor(caseData.expr.expr)}');
                    trace('[XRay compileStandardCase] Context: ${context != null ? "exists" : "null"}');
                    if (context != null) {
                        trace('[XRay compileStandardCase] structParamName: ${context.structParamName}');
                    }
                    #end
                    // Check if this is a direct field assignment that needs transformation
                    if (context != null && context.structParamName != null) {
                        #if debug_state_threading
                        trace('[XRay compileStandardCase] Checking for direct field assignment with context.structParamName = ${context.structParamName}');
                        #end
                        // Try to transform direct field assignments
                        var directAssignment = compiler.expressionDispatcher.controlFlowCompiler.analyzeDirectFieldAssignment(caseData.expr, context);
                        if (directAssignment != null) {
                            #if debug_state_threading
                            trace('[XRay compileStandardCase] ✓ Direct assignment found, using transformed code');
                            trace('[XRay compileStandardCase] Transformed: ${directAssignment.compiledCode}');
                            #end
                            directAssignment.compiledCode;
                        } else {
                            #if debug_state_threading
                            trace('[XRay compileStandardCase] ✗ No direct assignment found, using normal compilation');
                            #end
                            compiler.compileExpression(caseData.expr);
                        }
                    } else {
                        #if debug_state_threading
                        trace('[XRay compileStandardCase] ✗ No context or structParamName, using normal compilation');
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
            trace('[XRay PatternMatchingCompiler] ✓ CLEARED switch case body context');
            trace('[XRay PatternMatchingCompiler] ✓ CLEARED pattern usage context');
            #end
            
            // Restore the saved mapping if we removed it
            // CRITICAL FIX: Don't restore if the mapping is to g_counter - that's always wrong
            if (savedGMapping != null && !StringTools.endsWith(savedGMapping, "_counter")) {
                compiler.currentFunctionParameterMap.set("g", savedGMapping);
                #if debug_pattern_matching
                trace('[XRay PatternMatchingCompiler] RESTORED g -> ${savedGMapping} mapping after case body compilation');
                #end
            } else if (savedGMapping != null) {
                #if debug_pattern_matching
                trace('[XRay PatternMatchingCompiler] ⚠️ BLOCKED restoration of incorrect g -> ${savedGMapping} mapping after case body');
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
        ?context: reflaxe.elixir.helpers.ControlFlowCompiler.FunctionContext
    ): String {
        
        // CRITICAL FIX: Remove 'g' mapping before compiling switch expression
        // The 'g' variable should never be mapped to g_counter in switch expressions
        var savedGMapping: Null<String> = null;
        if (compiler.currentFunctionParameterMap.exists("g")) {
            savedGMapping = compiler.currentFunctionParameterMap.get("g");
            compiler.currentFunctionParameterMap.remove("g");
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] Temporarily removed g mapping before switch: g -> ${savedGMapping}');
            #end
        }
        
        var exprStr = compiler.compileExpression(switchExpr);
        
        // Restore the 'g' mapping after compilation
        // CRITICAL FIX: Don't restore if the mapping is to g_counter - that's always wrong
        if (savedGMapping != null && !StringTools.endsWith(savedGMapping, "_counter")) {
            compiler.currentFunctionParameterMap.set("g", savedGMapping);
        } else if (savedGMapping != null) {
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] ⚠️ BLOCKED restoration of incorrect g -> ${savedGMapping} mapping');
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
        ?context: reflaxe.elixir.helpers.ControlFlowCompiler.FunctionContext
    ): String {
        #if debug_pattern_matching
        trace("[PatternMatchingCompiler] ✓ RESULT SWITCH COMPILATION - Generating direct patterns");
        #end
        
        // CRITICAL FIX: Remove 'g' mapping before compiling switch expression
        // The 'g' variable should never be mapped to g_counter in switch expressions
        var savedGMapping: Null<String> = null;
        if (compiler.currentFunctionParameterMap.exists("g")) {
            savedGMapping = compiler.currentFunctionParameterMap.get("g");
            compiler.currentFunctionParameterMap.remove("g");
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] Temporarily removed g mapping in Result switch: g -> ${savedGMapping}');
            #end
        }
        
        // CRITICAL FIX: Compile the switch expression directly without enum introspection
        // This avoids the inner case statement that creates double-nesting
        // Debug what we're about to compile
        trace('[PatternMatchingCompiler] About to compile switch expression: ${switchExpr.expr}');
        
        // Special check for our problematic variables
        switch (switchExpr.expr) {
            case TLocal(v) if (v.name == "bulkAction" || v.name == "alertLevel"):
                trace('[PatternMatchingCompiler] ⚠️ COMPILING CAMELCASE VARIABLE: ${v.name}');
            case _:
        }
        
        var exprStr = compiler.compileExpression(switchExpr);
        trace('[PatternMatchingCompiler] Compiled switch expression to: ${exprStr}');
        
        // CRITICAL FIX: If the compiled expression contains a case statement, extract the variable
        // This handles situations where enum introspection was already applied
        if (exprStr.indexOf("case ") == 0 && exprStr.indexOf(" do ") > 0) {
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] ⚠️ DETECTED ENUM INTROSPECTION in Result switch - extracting variable');
            trace('[PatternMatchingCompiler] Original exprStr: ${exprStr}');
            #end
            
            // Extract the variable from "case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end"
            var caseStartIndex = exprStr.indexOf("case ") + 5;
            var doIndex = exprStr.indexOf(" do ");
            if (caseStartIndex < doIndex) {
                exprStr = exprStr.substring(caseStartIndex, doIndex);
                #if debug_pattern_matching
                trace('[PatternMatchingCompiler] ✓ EXTRACTED variable: ${exprStr}');
                #end
            }
        }
        
        // Restore the 'g' mapping after compilation
        // CRITICAL FIX: Don't restore if the mapping is to g_counter - that's always wrong
        if (savedGMapping != null && !StringTools.endsWith(savedGMapping, "_counter")) {
            compiler.currentFunctionParameterMap.set("g", savedGMapping);
        } else if (savedGMapping != null) {
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] ⚠️ BLOCKED restoration of incorrect g -> ${savedGMapping} mapping in Result switch');
            #end
        }
        
        var caseStrings: Array<String> = [];
        
        // Generate direct Result patterns for each case
        for (caseData in cases) {
            for (value in caseData.values) {
                #if debug_pattern_matching
                trace('[PatternMatchingCompiler] Processing Result case value: ${value.expr}');
                #end
                
                var pattern = switch (value.expr) {
                    case TConst(TInt(0)):
                        #if debug_pattern_matching
                        trace('[PatternMatchingCompiler] ✓ OK pattern (index 0)');
                        #end
                        "{:ok, _}"; // Ok constructor
                        
                    case TConst(TInt(1)):
                        #if debug_pattern_matching
                        trace('[PatternMatchingCompiler] ✓ ERROR pattern (index 1)');
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
                        trace('[PatternMatchingCompiler] ✓ FALLBACK pattern compilation');
                        #end
                        // Fall back to regular pattern compilation
                        compileEnumPattern(value);
                };
                
                var body = compilePatternBody(caseData.expr, context);
                caseStrings.push('  ${pattern} -> ${body}');
                
                #if debug_pattern_matching
                trace('[PatternMatchingCompiler] Generated Result case: ${pattern} -> [body]');
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
            trace('[PatternMatchingCompiler] WARNING: Fixed incorrect g_counter mapping to g');
            #end
        }
        
        var result = 'case ${exprStr} do\n${caseStrings.join("\n")}\nend';
        
        #if debug_pattern_matching
        trace('[PatternMatchingCompiler] ✓ RESULT SWITCH COMPLETE');
        trace('[PatternMatchingCompiler] Generated: ${result.substring(0, 100)}...');
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
        trace("[XRay filterPatternExtractionVars] START - Processing ${el.length} expressions");
        trace('[XRay filterPatternExtractionVars] Pattern vars count: ${Lambda.count(patternVars)}');
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
                                    trace('[XRay filterPatternExtractionVars] ✓ Keeping extraction var ${tvar.name} (used for pattern param ${index})');
                                    #end
                                } else {
                                    #if debug_pattern_matching
                                    trace('[XRay filterPatternExtractionVars] ✗ Marking orphaned extraction var ${tvar.name} (param ${index} not used in pattern)');
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
        trace('[XRay filterPatternExtractionVars] Found extraction vars: ${[for (k in allExtractionVars.keys()) k]}');
        trace('[XRay filterPatternExtractionVars] Used extraction vars: ${[for (k in usedExtractionVars.keys()) k]}');
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
        trace("[XRay filterPatternExtractionVars] END - Returning ${filtered.length} filtered expressions");
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
                        trace('[XRay collectExtractionVars] Found extraction var: ${tvar.name}');
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
                                trace('[XRay filterExpression] Filtering out ORPHANED enum parameter extraction: ${tvar.name}');
                                #end
                                return null; // Skip orphaned enum parameter extraction
                            } else {
                                #if debug_pattern_matching
                                trace('[XRay filterExpression] Keeping USED enum parameter extraction: ${tvar.name}');
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
                                trace('[XRay filterExpression] Filtering out pattern var assignment: ${tvar.name} = ${v.name}');
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
                trace("[XRay filterExpression] Processing TIf - filtering branches");
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
                                var varName = NamingHelper.toSnakeCase(patternVar.name);
                                patternVars.set(paramIndex, varName);
                                #if debug_pattern_matching
                                trace('[XRay PatternMatchingCompiler] ✓ Mapped param ${paramIndex} to variable: ${varName} (via ${v.name})');
                                #end
                            }
                        case _:
                    }
                case TBlock(el):
                    // Recurse into nested blocks
                    #if debug_pattern_matching
                    trace('[XRay PatternMatchingCompiler] Recursing into TBlock with ${el.length} expressions');
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
        trace("[XRay PatternMatchingCompiler] Extracting pattern variables from case body");
        #end
        
        switch (expr.expr) {
            case TBlock(el):
                #if debug_pattern_matching
                trace('[XRay PatternMatchingCompiler] Block has ${el.length} expressions');
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
                    trace('[XRay PatternMatchingCompiler] el[${k}]: ${exprStr}');
                }
                #end
                
                // First pass: Find all enum parameter extractions and map them
                var extractionVars = new Map<String, Int>(); // Maps extraction var name to param index
                for (i in 0...el.length) {
                    switch (el[i].expr) {
                        case TVar(tvar, e):
                            #if debug_pattern_matching
                            trace('[XRay PatternMatchingCompiler] Checking TVar: name="${tvar.name}", startsWith(_g)=${StringTools.startsWith(tvar.name, "_g")}, e!=null=${e != null}');
                            #end
                            if (StringTools.startsWith(tvar.name, "_g") && e != null) {
                                switch (e.expr) {
                                    case TEnumParameter(_, enumField, index):
                                        extractionVars.set(tvar.name, index);
                                        #if debug_pattern_matching
                                        trace('[XRay PatternMatchingCompiler] ✓ Found extraction: ${tvar.name} -> param ${index}');
                                        #end
                                    case _:
                                        #if debug_pattern_matching
                                        trace('[XRay PatternMatchingCompiler] TVar ${tvar.name} has non-TEnumParameter init: ${e.expr}');
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
                trace('[XRay PatternMatchingCompiler] Case body is not TBlock: ${expr.expr}');
                #end
        }
        
        #if debug_pattern_matching
        trace('[XRay PatternMatchingCompiler] Extracted ${Lambda.count(patternVars)} pattern variables');
        for (key in patternVars.keys()) {
            trace('[XRay PatternMatchingCompiler]   Param ${key}: ${patternVars.get(key)}');
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
     * @return Compiled pattern string with variables
     */
    private function compilePatternWithVariables(expr: TypedExpr, patternVars: Map<Int, String>): String {
        #if debug_pattern_matching
        trace('[XRay PatternMatchingCompiler] compilePatternWithVariables: expr=${expr.expr}, patternVars=${patternVars}');
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
                            varList.push(patternVars.get(i));
                        } else {
                            varList.push("_");
                        }
                    }
                    #if debug_pattern_matching
                    trace('[XRay PatternMatchingCompiler] Generating enum tuple pattern for index ${n}: {${n}, ${varList.join(", ")}}');
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
                        trace('[XRay PatternMatchingCompiler] Generating simple integer pattern for elem() switch: ${n}');
                    } else {
                        trace('[XRay PatternMatchingCompiler] Generating simple integer pattern: ${n}');
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
        
        if (args.length == 0) {
            return atom;
        }
        
        var argPatterns = args.map(arg -> compilePatternArgument(arg));
        return '{${atom}, ${argPatterns.join(", ")}}';
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
    private function compilePatternBody(expr: TypedExpr, ?context: reflaxe.elixir.helpers.ControlFlowCompiler.FunctionContext): String {
        #if debug_pattern_matching
        trace("[XRay PatternMatchingCompiler] CASE BODY COMPILATION START");
        trace('[XRay PatternMatchingCompiler] Body expression type: ${expr.expr}');
        trace('[XRay PatternMatchingCompiler] Context received: ${context != null ? "yes" : "no"}');
        if (context != null && context.structParamName != null) {
            trace('[XRay PatternMatchingCompiler] Context structParamName: ${context.structParamName}');
        }
        #end
        
        return switch (expr.expr) {
            case TBlock(el):
                #if debug_pattern_matching
                trace("[XRay PatternMatchingCompiler] ✓ DELEGATING TBlock to ControlFlowCompiler");
                trace('[XRay PatternMatchingCompiler] Block has ${el.length} expressions');
                for (i in 0...el.length) {
                    trace('[XRay PatternMatchingCompiler] Expression ${i}: ${el[i].expr}');
                }
                trace('[XRay PatternMatchingCompiler] Passing context to compileBlock: ${context != null ? "yes" : "no"}');
                #end
                
                // Use the passed context if available, otherwise don't pass context
                // This allows proper state threading transformation when context is provided
                var result = compiler.expressionDispatcher.controlFlowCompiler.compileBlock(el, false, context);
                
                #if debug_pattern_matching
                trace('[XRay PatternMatchingCompiler] ControlFlowCompiler result: ${result.substring(0, 100)}...');
                #end
                
                result;
                
            case TParenthesis(e):
                #if debug_pattern_matching
                trace("[XRay PatternMatchingCompiler] ✓ FOUND TParenthesis wrapping another expression");
                trace('[XRay PatternMatchingCompiler] Inner expression type: ${e.expr}');
                #end
                
                // Recursively process the parentheses content - this might be a TBlock!
                var result = compilePatternBody(e, context);
                
                #if debug_pattern_matching
                trace('[XRay PatternMatchingCompiler] TParenthesis result: ${result.substring(0, 100)}...');
                #end
                
                // The parentheses are already handled by the inner expression
                result;
                
            case _:
                #if debug_pattern_matching
                trace("[XRay PatternMatchingCompiler] ✓ USING standard compilation for non-block");
                trace('[XRay PatternMatchingCompiler] Context available: ${context != null}');
                if (context != null) {
                    trace('[XRay PatternMatchingCompiler] structParamName: ${context.structParamName}');
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
                    trace('[XRay PatternMatchingCompiler] ✓ Set temporary _this mapping to: ${context.structParamName}');
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
                    trace('[XRay PatternMatchingCompiler] ✓ Restored original _this mapping state');
                    #end
                }
                
                #if debug_pattern_matching
                trace('[XRay PatternMatchingCompiler] Standard result: ${result.substring(0, 100)}...');
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
        trace('[PatternMatchingCompiler] Checking for TEnumIndex pattern in switch expression');
        trace('[PatternMatchingCompiler] Switch expr type: ${switchExpr.expr}');
        #end
        
        switch (switchExpr.expr) {
            case TEnumIndex(innerExpr):
                #if debug_pattern_matching
                trace('[PatternMatchingCompiler] ✓ Found TEnumIndex pattern!');
                trace('[PatternMatchingCompiler] Inner expr type: ${innerExpr.t}');
                #end
                
                // Check if the inner expression is an enum type
                // We want to handle ALL enums directly to avoid double-nested case statements
                switch (innerExpr.t) {
                    case TEnum(enumRef, _):
                        var enumType = enumRef.get();
                        #if debug_pattern_matching
                        trace('[PatternMatchingCompiler] Enum type: ${enumType.name} - will use direct compilation');
                        #end
                        // Return true for ALL enum types to avoid double-nested case statements
                        // The compileSwitchOnEnumIndexDirectly method will handle different enum types appropriately
                        return true;
                    case _:
                        #if debug_pattern_matching
                        trace('[PatternMatchingCompiler] Inner expr is not enum type');
                        #end
                        return false;
                }
            case _:
                #if debug_pattern_matching
                trace('[PatternMatchingCompiler] Not a TEnumIndex pattern');
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
        ?context: reflaxe.elixir.helpers.ControlFlowCompiler.FunctionContext
    ): String {
        #if debug_pattern_matching
        trace("[PatternMatchingCompiler] ✓ DIRECT TSwitch(TEnumIndex) COMPILATION START");
        #end
        
        // Extract the inner expression from TEnumIndex
        var innerExpr = switch (switchExpr.expr) {
            case TEnumIndex(expr): expr;
            case _: 
                #if debug_pattern_matching
                trace("[PatternMatchingCompiler] ❌ ERROR: Not a TEnumIndex expression");
                #end
                return compileStandardCase(switchExpr, cases, defaultExpr, context);
        };
        
        // Determine the enum type
        var enumType = switch (innerExpr.t) {
            case TEnum(enumRef, _): enumRef.get();
            case _: 
                #if debug_pattern_matching
                trace("[PatternMatchingCompiler] ❌ ERROR: Inner expression is not enum type");
                #end
                return compileStandardCase(switchExpr, cases, defaultExpr, context);
        };
        
        #if debug_pattern_matching
        trace('[PatternMatchingCompiler] Enum type: ${enumType.name}');
        #end
        
        // Clean variable mapping for g parameter
        var savedGMapping: Null<String> = null;
        if (compiler.currentFunctionParameterMap.exists("g")) {
            savedGMapping = compiler.currentFunctionParameterMap.get("g");
            compiler.currentFunctionParameterMap.remove("g");
            #if debug_pattern_matching
            trace('[PatternMatchingCompiler] Temporarily removed g mapping: g -> ${savedGMapping}');
            #end
        }
        
        // Compile the inner expression directly (should be variable like "g")
        var innerExprStr = compiler.compileExpression(innerExpr);
        
        // Restore g mapping if it wasn't a counter variable
        if (savedGMapping != null && !StringTools.endsWith(savedGMapping, "_counter")) {
            compiler.currentFunctionParameterMap.set("g", savedGMapping);
        }
        
        #if debug_pattern_matching
        trace('[PatternMatchingCompiler] Inner expression compiled to: ${innerExprStr}');
        #end
        
        // Generate direct patterns based on enum type
        var caseStrings: Array<String> = [];
        
        // Check if this enum has parameters
        var hasParameters = false;
        for (name in enumType.names) {
            var construct = enumType.constructs.get(name);
            if (construct != null && construct.params.length > 0) {
                hasParameters = true;
                break;
            }
        }
        
        #if debug_pattern_matching
        trace('[PatternMatchingCompiler] Enum ${enumType.name} has parameters: ${hasParameters}');
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
                            // For enums with parameters, use tuple patterns
                            if (index >= 0 && index < enumType.names.length) {
                                var constructorName = enumType.names[index];
                                var construct = enumType.constructs.get(constructorName);
                                if (construct != null && construct.params.length == 0) {
                                    // Constructor without parameters in an enum that has some with parameters
                                    '{:' + NamingHelper.toSnakeCase(constructorName) + '}';
                                } else {
                                    // Constructor with parameters - use wildcard for now
                                    '{:' + NamingHelper.toSnakeCase(constructorName) + ', _}';
                                }
                            } else {
                                "_"; // Fallback
                            }
                        };
                    case _: "_"; // Catch-all for non-constant patterns
                };
                
                var body = compilePatternBody(caseData.expr, context);
                caseStrings.push('  ${pattern} -> ${body}');
                
                #if debug_pattern_matching
                trace('[PatternMatchingCompiler] Generated direct pattern: ${pattern} -> [body]');
                #end
            }
        }
        
        // Add default case if present
        if (defaultExpr != null) {
            var defaultBody = compilePatternBody(defaultExpr, context);
            caseStrings.push('  _ -> ${defaultBody}');
        }
        
        var result = 'case ${innerExprStr} do\n${caseStrings.join("\n")}\nend';
        
        #if debug_pattern_matching
        trace("[PatternMatchingCompiler] ✓ DIRECT TSwitch(TEnumIndex) COMPILATION END");
        trace('[PatternMatchingCompiler] Generated clean case: ${result.substring(0, 100)}...');
        #end
        
        return result;
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
        trace('[XRay PatternMatchingCompiler] FINDING USED VARIABLES in expression type: ${Type.enumConstructor(expr.expr)}');
        #end
        
        function analyzeExpression(e: TypedExpr): Void {
            switch (e.expr) {
                case TLocal(v):
                    // Direct variable reference - mark as used
                    usedVars.set(v.name, true);
                    #if debug_pattern_matching
                    trace('[XRay PatternMatchingCompiler] ✓ Found variable usage: ${v.name}');
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
                    trace('[XRay PatternMatchingCompiler] ⚠️ Unhandled expression type in usage analysis: ${Type.enumConstructor(e.expr)}');
                    #end
            }
        }
        
        // Start analysis from root expression
        analyzeExpression(expr);
        
        #if debug_pattern_matching
        var varNames = [for (name in usedVars.keys()) name];
        trace('[XRay PatternMatchingCompiler] Used variables found: [${varNames.join(", ")}]');
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
        trace('[XRay PatternMatchingCompiler] detectElemBasedSwitch: analyzing ${switchExpr.expr}');
        #end
        
        return switch (switchExpr.expr) {
            case TCall(e, args):
                // Check if this is a call to elem()
                switch (e.expr) {
                    case TField(_, FStatic(_, cf)) if (cf.get().name == "elem"):
                        #if debug_pattern_matching
                        trace('[XRay PatternMatchingCompiler] ✓ Found elem() call - this is elem() based switch');
                        #end
                        true;
                    case TField(_, FEnum(_, _)):
                        // This is enum constructor call, not elem()
                        #if debug_pattern_matching
                        trace('[XRay PatternMatchingCompiler] Found enum constructor call - this is direct enum switch');
                        #end
                        false;
                    case _:
                        #if debug_pattern_matching
                        trace('[XRay PatternMatchingCompiler] Call to non-elem function');
                        #end
                        false;
                }
            case TLocal(_):
                // Local variable - could be either type, assume direct enum
                #if debug_pattern_matching
                trace('[XRay PatternMatchingCompiler] Local variable - assuming direct enum switch');
                #end
                false;
            case _:
                #if debug_pattern_matching
                trace('[XRay PatternMatchingCompiler] Other expression type - assuming direct enum switch');
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
        ?context: reflaxe.elixir.helpers.ControlFlowCompiler.FunctionContext,
        ?enumType: EnumType
    ): String {
        #if debug_pattern_matching
        trace('[PatternMatchingCompiler] ✓ ENUM INDEX SWITCH COMPILATION START');
        trace('[PatternMatchingCompiler] Enum type: ${enumType != null ? enumType.name : "null"}');
        trace('[PatternMatchingCompiler] Cases: ${cases.length}');
        #end
        
        // Mark this as an elem() based switch for pattern generation
        currentSwitchIsElemBased = true;
        
        // Compile switch expression to get the variable name
        var switchVarStr = compiler.compileExpression(switchExpr);
        
        // Generate case(elem(switchExpr, 0)) do
        var exprStr = 'elem(${switchVarStr}, 0)';
        
        #if debug_pattern_matching
        trace('[PatternMatchingCompiler] Switch expression: ${exprStr}');
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
            trace('[PatternMatchingCompiler] Processing case with ${caseData.values.length} values');
            #end
            
            // Extract pattern variables from case body
            var patternVars = extractPatternVariables(caseData.expr);
            
            for (value in caseData.values) {
                var pattern = null;
                var caseIndex = -1;
                
                // Determine the enum constructor index
                switch (value.expr) {
                    case TCall(e, args):
                        switch (e.expr) {
                            case TField(_, FEnum(enumRef, enumField)):
                                caseIndex = enumConstructors.indexOf(enumField.name);
                                #if debug_pattern_matching
                                trace('[PatternMatchingCompiler] Found enum constructor ${enumField.name} at index ${caseIndex}');
                                #end
                            case _:
                                #if debug_pattern_matching
                                trace('[PatternMatchingCompiler] TCall with non-enum field');
                                #end
                        }
                    case TConst(TInt(n)):
                        caseIndex = n;
                        #if debug_pattern_matching
                        trace('[PatternMatchingCompiler] Found integer pattern ${n}');
                        #end
                    case _:
                        #if debug_pattern_matching
                        trace('[PatternMatchingCompiler] Other pattern type: ${value.expr}');
                        #end
                }
                
                if (caseIndex >= 0) {
                    pattern = Std.string(caseIndex);
                    #if debug_pattern_matching
                    trace('[PatternMatchingCompiler] Generated pattern: ${pattern}');
                    #end
                }
                
                if (pattern != null) {
                    // Set up pattern usage context for enum parameter extraction
                    var usedVariables = findUsedVariables(caseData.expr);
                    compiler.patternUsageContext = usedVariables;
                    compiler.currentSwitchCaseBody = caseData.expr;
                    
                    // Compile case body with pattern variable extraction
                    var body = compilePatternBody(caseData.expr, context);
                    
                    // Clear context
                    compiler.patternUsageContext = null;
                    compiler.currentSwitchCaseBody = null;
                    
                    caseStrings.push('  ${pattern} ->\n    ${body}');
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
        trace('[PatternMatchingCompiler] ✓ ENUM INDEX SWITCH COMPILATION END');
        trace('[PatternMatchingCompiler] Result: ${result.substring(0, 200)}...');
        #end
        
        return result;
    }
}

#end