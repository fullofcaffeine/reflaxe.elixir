package reflaxe.elixir.helpers;

#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
using haxe.macro.TypedExprTools;
#end

/**
 * Professional debug infrastructure for Reflaxe.Elixir compiler development
 * 
 * This module provides conditional debug capabilities that can be enabled/disabled
 * at compile time using Haxe's conditional compilation system. This ensures
 * zero performance impact in production builds while providing comprehensive
 * debugging capabilities during compiler development.
 * 
 * ## Usage Patterns
 * 
 * Enable debugging via build flags:
 * ```bash
 * # Enable all debugging
 * npx haxe build.hxml -D debug_compiler
 * 
 * # Enable specific categories  
 * npx haxe build.hxml -D debug_patterns -D debug_annotations -D debug_expressions
 * 
 * # Production build (no debug output)
 * npx haxe build.hxml
 * ```
 * 
 * Use in compiler code:
 * ```haxe
 * #if debug_for_loops
 *     DebugHelper.debugForLoop("TFor compilation", tvar, iterExpr, blockExpr);
 * #end
 * 
 * #if debug_patterns
 *     DebugHelper.debugPattern("Y combinator detection", pattern, result);
 * #end
 * 
 * #if debug_annotations
 *     DebugHelper.debugInfo("@:router processing", "Building routes for: " + className);
 * #end
 * 
 * #if debug_expressions
 *     DebugHelper.debugExpression("TCall compilation", expr, result);
 * #end
 * ```
 * 
 * ## Debug Categories
 * 
 * - **debug_compiler**: General compiler debugging (enables all categories)
 * - **debug_for_loops**: For-loop compilation and optimization
 * - **debug_patterns**: Pattern detection and matching (Map.merge, Y combinator, etc.)
 * - **debug_optimizations**: Optimization decisions and results
 * - **debug_ast**: AST structure analysis
 * - **debug_expressions**: Expression compilation details
 * - **debug_types**: Type resolution and mapping
 * - **debug_annotations**: Annotation processing (@:liveview, @:router, etc.)
 * - **debug_helpers**: Helper compiler debugging (EnumCompiler, ClassCompiler, etc.)
 * - **debug_y_combinator**: Y combinator generation and related syntax issues
 * - **debug_if_expressions**: If-expression compilation (inline vs block syntax)
 * - **debug_variable_tracking**: Variable name tracking and renaming throughout compilation
 * 
 * @see CLAUDE.md - Complete debug infrastructure documentation
 */
class DebugHelper {
    
    /**
     * Debug for-loop compilation process
     * 
     * Traces the complete for-loop compilation flow including variable analysis,
     * iterator expression details, block structure, and optimization decisions.
     * 
     * @param context Brief description of the compilation context
     * @param tvar The loop variable from TFor
     * @param iterExpr The iteration expression (e.g., Reflect.fields call)
     * @param blockExpr The loop body expression
     */
    #if macro
    public static function debugForLoop(context: String, tvar: TVar, iterExpr: TypedExpr, blockExpr: TypedExpr): Void {
        #if (debug_compiler || debug_for_loops)
        trace('[DEBUG:FOR_LOOP] ==================================================');
        trace('Context: $context');
        trace('Variable: ${tvar.name} (${getTypeName(tvar.t)})');
        trace('Iterator: ${prettifyExpression(iterExpr)}');
        trace('Block Type: ${getExpressionTypeName(blockExpr)}');
        trace('Block Content: ${prettifyExpression(blockExpr)}');
        trace('[DEBUG:END] ======================================================');
        #end
    }
    #end
    
    /**
     * Debug pattern detection results
     * 
     * Traces pattern matching attempts, including what pattern was searched for,
     * what was found, and whether the pattern was successfully detected.
     * 
     * @param context Description of the pattern being detected
     * @param pattern The pattern being searched for
     * @param result The detection result (true/false or detailed result)
     */
    public static function debugPattern(context: String, pattern: String, result: Dynamic): Void {
        #if (debug_compiler || debug_patterns)
        trace('[DEBUG:PATTERN] ================================================');
        trace('Context: $context');
        trace('Pattern: $pattern');
        trace('Result: $result');
        trace('[DEBUG:END] ====================================================');
        #end
    }
    
    /**
     * Debug optimization decisions
     * 
     * Traces when optimizations are applied, including the original code,
     * the optimized result, and the reasoning for the optimization.
     * 
     * @param optimization The type of optimization being applied
     * @param before The original code/pattern before optimization
     * @param after The optimized result
     * @param reason Optional explanation of why this optimization was chosen
     */
    public static function debugOptimization(optimization: String, before: String, after: String, ?reason: String): Void {
        #if (debug_compiler || debug_optimizations)
        trace('[DEBUG:OPTIMIZATION] ==========================================');
        trace('Optimization: $optimization');
        trace('Before: $before');
        trace('After: $after');
        if (reason != null) trace('Reason: $reason');
        trace('[DEBUG:END] ==============================================');
        #end
    }
    
    /**
     * Debug AST structure analysis
     * 
     * Provides detailed breakdown of TypedExpr AST nodes, useful for
     * understanding complex expression structures and debugging
     * AST transformation issues.
     * 
     * @param context Description of what AST is being analyzed
     * @param expr The TypedExpr to analyze
     */
    #if macro
    public static function debugAST(context: String, expr: TypedExpr): Void {
        #if (debug_compiler || debug_ast)
        trace('[DEBUG:AST] ===================================================');
        trace('Context: $context');
        trace('Expression Type: ${getExpressionTypeName(expr)}');
        trace('Haxe Type: ${getTypeName(expr.t)}');
        trace('Position: ${expr.pos}');
        trace('Structure: ${getASTStructure(expr)}');
        trace('[DEBUG:END] =======================================================');
        #end
    }
    #end
    
    /**
     * Debug expression compilation details
     * 
     * Traces the compilation process for individual expressions,
     * showing the input AST and the generated Elixir code.
     * 
     * @param context Description of the expression being compiled
     * @param expr The input TypedExpr
     * @param result The compiled Elixir code string
     */
    #if macro
    public static function debugExpression(context: String, expr: TypedExpr, result: String): Void {
        #if (debug_compiler || debug_expressions)
        trace('[DEBUG:EXPRESSION] =============================================');
        trace('Context: $context');
        trace('Input: ${prettifyExpression(expr)}');
        trace('Output: $result');
        trace('[DEBUG:END] =================================================');
        #end
    }
    #end
    
    /**
     * Debug general compiler information
     * 
     * For general debugging that doesn't fit into other categories.
     * 
     * @param context Description of what is being debugged
     * @param info The information to display
     */
    public static function debugInfo(context: String, info: String): Void {
        #if debug_compiler
        trace('[DEBUG:INFO] ==================================================');
        trace('Context: $context');
        trace('Info: $info');
        trace('[DEBUG:END] ======================================================');
        #end
    }
    
    /**
     * Debug Y combinator generation and compilation
     * 
     * Traces Y combinator creation, syntax issues, and related optimizations.
     * Critical for debugging the `, else: nil` syntax error.
     * 
     * @param context Description of Y combinator context
     * @param stage Current stage (generation, compilation, optimization)
     * @param details Specific details about the Y combinator
     */
    public static function debugYCombinator(context: String, stage: String, details: String): Void {
        #if (debug_compiler || debug_y_combinator)
        trace('[DEBUG:Y_COMBINATOR] ==========================================');
        trace('Context: $context');
        trace('Stage: $stage');
        trace('Details: $details');
        trace('[DEBUG:END] ==============================================');
        #end
    }
    
    /**
     * Debug if-expression compilation decisions
     * 
     * Traces inline vs block syntax decisions, nested if handling,
     * and where `, else: nil` might be incorrectly appended.
     * 
     * @param context Description of if-expression context
     * @param decision Whether using inline or block syntax
     * @param reason Why this decision was made
     * @param result The generated Elixir code
     */
    public static function debugIfExpression(context: String, decision: String, reason: String, result: String): Void {
        #if (debug_compiler || debug_if_expressions)
        trace('[DEBUG:IF_EXPR] ===============================================');
        trace('Context: $context');
        trace('Decision: $decision');
        trace('Reason: $reason');
        trace('Result: $result');
        trace('[DEBUG:END] ==================================================');
        #end
    }
    
    /**
     * Debug inline if-statement generation
     * 
     * Traces inline if-statement generation across different compilation paths.
     * Critical for debugging Y combinator syntax errors and missing `, else: nil` completions.
     * 
     * @param context Description of inline if context
     * @param stage Current compilation stage
     * @param condition The if condition being compiled
     * @param result The complete generated inline if statement
     */
    public static function debugInlineIf(context: String, stage: String, condition: String, result: String): Void {
        #if (debug_compiler || debug_inline_if)
        trace('[DEBUG:INLINE_IF] ============================================');
        trace('Context: $context');
        trace('Stage: $stage');
        trace('Condition: $condition');
        trace('Result: $result');
        trace('[DEBUG:END] ==================================================');
        #end
    }
    
    /**
     * Debug variable name tracking and renaming
     * 
     * Tracks how variables are renamed during compilation,
     * critical for understanding Map.merge variable issues.
     * 
     * @param context Description of variable tracking context
     * @param originalName Original variable name from Haxe
     * @param renamedTo What the variable was renamed to
     * @param reason Why the renaming occurred
     */
    public static function debugVariableTracking(context: String, originalName: String, renamedTo: String, reason: String): Void {
        #if (debug_compiler || debug_variable_tracking)
        trace('[DEBUG:VAR_TRACK] =============================================');
        trace('Context: $context');
        trace('Original: $originalName');
        trace('Renamed To: $renamedTo');
        trace('Reason: $reason');
        trace('[DEBUG:END] ===============================================');
        #end
        
    }
    
    // Helper functions for pretty-printing
    
    #if macro
    /**
     * Get a human-readable type name from Type
     */
    private static function getTypeName(type: Type): String {
        return switch (type) {
            case TInst(t, params): t.get().name + (params.length > 0 ? '<${params.map(getTypeName).join(", ")}>' : "");
            case TEnum(t, params): t.get().name + (params.length > 0 ? '<${params.map(getTypeName).join(", ")}>' : "");
            case TType(t, params): t.get().name + (params.length > 0 ? '<${params.map(getTypeName).join(", ")}>' : "");
            case TFun(args, ret): '(${args.map(a -> '${a.name}:${getTypeName(a.t)}').join(", ")}) -> ${getTypeName(ret)}';
            case TMono(t): t.get() != null ? getTypeName(t.get()) : "Unknown";
            case TAbstract(t, params): t.get().name + (params.length > 0 ? '<${params.map(getTypeName).join(", ")}>' : "");
            case TDynamic(t): t != null ? 'Dynamic<${getTypeName(t)}>' : "Dynamic";
            case TLazy(f): getTypeName(f());
            case TAnonymous(a): "Anonymous";
        }
    }
    
    /**
     * Get a human-readable expression type name
     */
    private static function getExpressionTypeName(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TConst(_): "TConst";
            case TLocal(_): "TLocal";
            case TArray(_, _): "TArray";
            case TBinop(_, _, _): "TBinop";
            case TField(_, _): "TField";
            case TTypeExpr(_): "TTypeExpr";
            case TParenthesis(_): "TParenthesis";
            case TObjectDecl(_): "TObjectDecl";
            case TArrayDecl(_): "TArrayDecl";
            case TCall(_, _): "TCall";
            case TNew(_, _, _): "TNew";
            case TUnop(_, _, _): "TUnop";
            case TFunction(_): "TFunction";
            case TVar(_, _): "TVar";
            case TBlock(_): "TBlock";
            case TFor(_, _, _): "TFor";
            case TIf(_, _, _): "TIf";
            case TWhile(_, _, _): "TWhile";
            case TSwitch(_, _, _): "TSwitch";
            case TTry(_, _): "TTry";
            case TReturn(_): "TReturn";
            case TBreak: "TBreak";
            case TContinue: "TContinue";
            case TThrow(_): "TThrow";
            case TCast(_, _): "TCast";
            case TMeta(_, _): "TMeta";
            case TEnumParameter(_, _, _): "TEnumParameter";
            case TEnumIndex(_): "TEnumIndex";
            case TIdent(_): "TIdent";
        }
    }
    
    /**
     * Create a pretty-printed version of a TypedExpr
     */
    private static function prettifyExpression(expr: TypedExpr, maxLength: Int = 100): String {
        var str = expr.toString();
        if (str.length > maxLength) {
            str = str.substr(0, maxLength - 3) + "...";
        }
        return str;
    }
    
    /**
     * Get a structured view of AST for debugging
     */
    private static function getASTStructure(expr: TypedExpr, depth: Int = 0): String {
        if (depth > 3) return "..."; // Prevent infinite recursion
        
        var indent = "";
        for (i in 0...depth) indent += "  ";
        var typeName = getExpressionTypeName(expr);
        
        return switch (expr.expr) {
            case TBlock(exprs):
                '$typeName[${exprs.length} expressions]';
            case TCall(e, args):
                '$typeName(${getExpressionTypeName(e)}, [${args.length} args])';
            case TFor(tvar, iterExpr, blockExpr):
                '$typeName(${tvar.name}, ${getExpressionTypeName(iterExpr)}, ${getExpressionTypeName(blockExpr)})';
            case TIf(cond, eif, eelse):
                '$typeName(${getExpressionTypeName(cond)}, ${getExpressionTypeName(eif)}, ${eelse != null ? getExpressionTypeName(eelse) : "null"})';
            case _:
                typeName;
        }
    }
    #end
}