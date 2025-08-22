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
            var patterns = caseData.values.map(v -> compilePattern(v));
            
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
                    // Pass context to ControlFlowCompiler for _this replacement
                    compiler.expressionDispatcher.controlFlowCompiler.compileBlock(el, false, context);
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