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
        
        #if debug_pattern_matching
        trace("[PatternMatchingCompiler] Compiling switch expression");
        trace('[PatternMatchingCompiler] Switch expr type: ${switchExpr.t}');
        trace('[PatternMatchingCompiler] Number of cases: ${cases.length}');
        #end
        
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
            trace('[PatternMatchingCompiler] Detected enum type: ${enumType.name}');
            #end
            
            // Special handling for Option and Result types
            if (isOptionType(enumType)) {
                return compileOptionSwitch(switchExpr, cases, defaultExpr, context);
            } else if (isResultType(enumType)) {
                return compileResultSwitch(switchExpr, cases, defaultExpr, context);
            }
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
        
        var exprStr = compiler.compileExpression(switchExpr);
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
                            // Standard enum pattern
                            compileTuplePattern(enumField.name, args);
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
                enumRef.get();
            case TAbstract(_, _):
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
     * Compile standard case statement
     */
    private function compileStandardCase(
        switchExpr: TypedExpr,
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>,
        defaultExpr: Null<TypedExpr>,
        ?context: reflaxe.elixir.helpers.ControlFlowCompiler.FunctionContext
    ): String {
        
        var exprStr = compiler.compileExpression(switchExpr);
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
                    var filteredEl = filterPatternExtractionVars(el);
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
            
            // Restore the saved mapping if we removed it
            if (savedGMapping != null) {
                compiler.currentFunctionParameterMap.set("g", savedGMapping);
                #if debug_pattern_matching
                trace('[XRay PatternMatchingCompiler] RESTORED g -> ${savedGMapping} mapping after case body compilation');
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
        
        var exprStr = compiler.compileExpression(switchExpr);
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
     */
    private function compileResultSwitch(
        switchExpr: TypedExpr,
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>,
        defaultExpr: Null<TypedExpr>,
        ?context: reflaxe.elixir.helpers.ControlFlowCompiler.FunctionContext
    ): String {
        
        return compileOptionSwitch(switchExpr, cases, defaultExpr, context); // Similar logic
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
     * 1. TVar expressions that extract enum parameters (_g variables)
     * 2. TVar expressions that reassign pattern variables from extraction vars
     * 
     * HOW: Two-phase approach:
     * 1. Collect all extraction variable names from the entire expression tree
     * 2. Filter and recursively transform expressions, removing redundant assignments
     * 
     * @param el The block expressions to filter
     * @return Filtered expressions without pattern extraction code
     */
    private function filterPatternExtractionVars(el: Array<TypedExpr>): Array<TypedExpr> {
        #if debug_pattern_matching
        trace("[XRay filterPatternExtractionVars] START - Processing ${el.length} expressions");
        #end
        
        // Phase 1: Collect all extraction variable names from the entire tree
        var extractionVars = new Map<String, Bool>();
        collectExtractionVarsRecursive(el, extractionVars);
        
        #if debug_pattern_matching
        trace('[XRay filterPatternExtractionVars] Found extraction vars: ${[for (k in extractionVars.keys()) k]}');
        #end
        
        // Phase 2: Filter expressions recursively
        var filtered = [];
        for (expr in el) {
            var processedExpr = filterExpressionRecursive(expr, extractionVars);
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
     * @return The filtered expression, or null if it should be removed entirely
     */
    private function filterExpressionRecursive(expr: TypedExpr, extractionVars: Map<String, Bool>): Null<TypedExpr> {
        switch (expr.expr) {
            case TVar(tvar, e):
                // Check if this should be filtered out
                if (StringTools.startsWith(tvar.name, "_g") && e != null) {
                    switch (e.expr) {
                        case TEnumParameter(_, _, _):
                            #if debug_pattern_matching
                            trace('[XRay filterExpression] Filtering out enum parameter extraction: ${tvar.name}');
                            #end
                            return null; // Skip enum parameter extraction
                        case _:
                    }
                } else if (e != null) {
                    // Check if this is a redundant pattern variable assignment
                    switch (e.expr) {
                        case TLocal(v):
                            if (extractionVars.exists(v.name)) {
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
                    var processedExpr = filterExpressionRecursive(e, extractionVars);
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
                
                var filteredIf = filterExpressionRecursive(eif, extractionVars);
                var filteredElse = eelse != null ? filterExpressionRecursive(eelse, extractionVars) : null;
                
                // Create new TIf with filtered branches
                return {
                    expr: TIf(cond, filteredIf != null ? filteredIf : eif, filteredElse),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TParenthesis(e):
                // Recursively filter parenthesis content
                var filtered = filterExpressionRecursive(e, extractionVars);
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
                var filtered = filterExpressionRecursive(e, extractionVars);
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
                var filtered = filterExpressionRecursive(e, extractionVars);
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
                
                // Second pass: Find pattern variable assignments that use these extraction vars
                for (i in 0...el.length) {
                    switch (el[i].expr) {
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
                        case _:
                    }
                }
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
                if (Lambda.count(patternVars) > 0) {
                    // This is an enum constructor match with parameters
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
                    trace('[XRay PatternMatchingCompiler] Generating enum pattern for index ${n}: {${n}, ${varList.join(", ")}}');
                    #end
                    
                    // For integer patterns with variables, generate tuple pattern
                    if (varList.length > 0) {
                        '{${n}, ${varList.join(", ")}}';
                    } else {
                        Std.string(n);
                    }
                } else {
                    // Simple integer pattern
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
}

#end