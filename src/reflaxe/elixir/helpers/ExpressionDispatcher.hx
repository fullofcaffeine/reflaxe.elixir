package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.BaseCompiler;

using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * Expression Dispatcher for Reflaxe.Elixir
 * 
 * WHY: The compileElixirExpressionInternal function was 2,011 lines - a massive "God function"
 * that violated Single Responsibility Principle by handling every possible TypedExpr case.
 * This created maintenance nightmares and made the code impossible to understand or extend.
 * 
 * WHAT: Central dispatch coordinator that routes TypedExpr compilation to specialized compilers:
 * - Routes TConst expressions → LiteralCompiler (constants, strings, numbers)
 * - Routes TLocal/TVar expressions → VariableCompiler (local variables, parameter mapping)
 * - Routes TBinop/TUnop expressions → OperatorCompiler (arithmetic, logical, assignment)
 * - Routes TIf/TSwitch/TTry expressions → ControlFlowCompiler (conditional logic)
 * - Routes TBlock expressions → BlockCompiler (statement sequences)
 * - Routes TArray/TObjectDecl expressions → DataStructureCompiler (collections)
 * - Routes TCall/TField expressions → MethodCallCompiler (already extracted)
 * - Routes complex patterns → specialized helper compilers as needed
 * 
 * HOW: The dispatcher implements a clean routing pattern:
 * 1. Receives TypedExpr from main ElixirCompiler.compileExpressionImpl()
 * 2. Analyzes the expression type via pattern matching
 * 3. Delegates to appropriate specialized compiler
 * 4. Returns compiled Elixir code string
 * 5. Provides extension points for new expression types
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Each compiler handles one expression category
 * - Open/Closed Principle: Easy to add new expression types without modifying existing code
 * - Testability: Each specialized compiler can be unit tested independently
 * - Maintainability: Clear separation of concerns makes debugging straightforward
 * - Performance: Faster compilation through focused, optimized handlers
 * 
 * EDGE CASES:
 * - Unknown expression types fall back to warning + nil generation
 * - Complex nested expressions are recursively dispatched
 * - Context-sensitive expressions (like LiveView assigns) are handled in specialized compilers
 * - Debug tracing provides visibility into dispatch decisions
 * 
 * @see documentation/EXPRESSION_COMPILATION_ARCHITECTURE.md - Complete dispatch patterns
 */
@:nullSafety(Off)
class ExpressionDispatcher {
    
    var compiler: Dynamic; // ElixirCompiler reference
    
    // Specialized compilers (will be created as we extract more functionality)
    public var literalCompiler: LiteralCompiler;
    var controlFlowCompiler: ControlFlowCompiler;
    var operatorCompiler: OperatorCompiler;
    // TODO: Uncomment as compilers are extracted:
    var variableCompiler: VariableCompiler;
    var dataStructureCompiler: DataStructureCompiler;
    var fieldAccessCompiler: FieldAccessCompiler;
    var methodCallCompiler: MethodCallCompiler;
    var miscExpressionCompiler: MiscExpressionCompiler;
    var enumIntrospectionCompiler: EnumIntrospectionCompiler;
    
    /**
     * Create a new expression dispatcher
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: Dynamic) {
        this.compiler = compiler;
        
        // Initialize specialized compilers
        this.literalCompiler = new LiteralCompiler(compiler);
        this.controlFlowCompiler = new ControlFlowCompiler(compiler);
        this.operatorCompiler = new OperatorCompiler(compiler, this.literalCompiler);
        this.methodCallCompiler = new MethodCallCompiler(compiler);
        
        // TODO: Initialize other compilers as they're extracted:
        this.variableCompiler = new VariableCompiler(compiler);
        this.dataStructureCompiler = new DataStructureCompiler(compiler);
        this.fieldAccessCompiler = new FieldAccessCompiler(compiler);
        this.miscExpressionCompiler = new MiscExpressionCompiler(compiler);
        this.enumIntrospectionCompiler = new EnumIntrospectionCompiler(compiler);
    }
    
    /**
     * Dispatch TypedExpr compilation to appropriate specialized compiler
     * 
     * WHY: Main entry point that replaces the 2,011-line compileElixirExpressionInternal function
     * 
     * WHAT: Routes expressions by type to specialized compilers using clean dispatch pattern
     * 
     * HOW:
     * 1. Debug trace the expression type and structure
     * 2. Pattern match on expr.expr to determine expression category
     * 3. Delegate to appropriate specialized compiler
     * 4. Return compiled Elixir code string
     * 5. Provide fallback for unknown expression types
     * 
     * @param expr The TypedExpr to compile
     * @param topLevel Whether this is a top-level expression
     * @return Compiled Elixir code string
     */
    public function compileExpression(expr: TypedExpr, topLevel: Bool = false): Null<String> {
        #if debug_expression_dispatcher
        trace("[XRay ExpressionDispatcher] EXPRESSION COMPILATION START");
        trace('[XRay ExpressionDispatcher] Expression type: ${expr.expr}');
        trace('[XRay ExpressionDispatcher] Top level: ${topLevel}');
        #end
        
        // Gradual extraction - dispatch to specialized compilers
        var result = switch (expr.expr) {
            case TConst(constant):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to LiteralCompiler");
                #end
                literalCompiler.compileConstant(constant);
                
            case TBlock(el):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to ControlFlowCompiler (TBlock)");
                #end
                controlFlowCompiler.compileBlock(el, topLevel);
                
            case TIf(econd, eif, eelse):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to ControlFlowCompiler (TIf)");
                #end
                controlFlowCompiler.compileIfExpression(econd, eif, eelse);
                
            case TSwitch(e, cases, edef):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to ControlFlowCompiler (TSwitch)");
                #end
                controlFlowCompiler.compileSwitchExpression(e, cases, edef);
                
            case TWhile(econd, ebody, normalWhile):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to ControlFlowCompiler (TWhile)");
                #end
                controlFlowCompiler.compileWhileLoop(econd, ebody, normalWhile);
                
            case TFor(tvar, iterExpr, blockExpr):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to ControlFlowCompiler (TFor)");
                #end
                controlFlowCompiler.compileForLoop(tvar, iterExpr, blockExpr);
                
            case TTry(e, catches):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to ControlFlowCompiler (TTry)");
                #end
                controlFlowCompiler.compileTryExpression(e, catches);
                
            case TBinop(op, e1, e2):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to OperatorCompiler (TBinop)");
                #end
                operatorCompiler.compileBinaryOperation(op, e1, e2);
                
            case TUnop(op, postFix, e):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to OperatorCompiler (TUnop)");
                #end
                operatorCompiler.compileUnaryOperation(op, postFix, e);
                
            case TArrayDecl(el):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to DataStructureCompiler (TArrayDecl)");
                #end
                dataStructureCompiler.compileArrayLiteral(el);
                
            case TObjectDecl(fields):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to DataStructureCompiler (TObjectDecl)");
                #end
                dataStructureCompiler.compileObjectDeclaration(fields);
                
            case TArray(e1, e2):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to DataStructureCompiler (TArray)");
                #end
                dataStructureCompiler.compileArrayIndexing(e1, e2);
                
            case TLocal(v):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to VariableCompiler (TLocal)");
                #end
                variableCompiler.compileLocalVariable(v);
                
            case TVar(tvar, expr):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to VariableCompiler (TVar)");
                #end
                variableCompiler.compileVariableDeclaration(tvar, expr);
                
            case TField(e, fa):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to FieldAccessCompiler (TField)");
                #end
                fieldAccessCompiler.compileFieldAccess(e, fa, expr);
                
            case TCall(e, el):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MethodCallCompiler (TCall)");
                #end
                methodCallCompiler.compileCallExpression(e, el);
                
            case TReturn(e):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TReturn)");
                #end
                miscExpressionCompiler.compileReturnStatement(e);
                
            case TParenthesis(e):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TParenthesis)");
                #end
                miscExpressionCompiler.compileParenthesesExpression(e);
                
            case TNew(c, params, el):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TNew)");
                #end
                miscExpressionCompiler.compileNewExpression(c, params, el);
                
            case TFunction(func):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TFunction)");
                #end
                miscExpressionCompiler.compileLambdaFunction(func);
                
            case TMeta(metadata, expr):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TMeta)");
                #end
                miscExpressionCompiler.compileMetadataExpression(metadata, expr);
                
            case TThrow(e):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TThrow)");
                #end
                miscExpressionCompiler.compileThrowStatement(e);
                
            case TCast(e, moduleType):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TCast)");
                #end
                miscExpressionCompiler.compileCastExpression(e, moduleType);
                
            case TTypeExpr(moduleType):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TTypeExpr)");
                #end
                miscExpressionCompiler.compileTypeExpression(moduleType);
                
            case TBreak:
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TBreak)");
                #end
                miscExpressionCompiler.compileBreakStatement();
                
            case TContinue:
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TContinue)");
                #end
                miscExpressionCompiler.compileContinueStatement();
                
            case TEnumIndex(e):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to EnumIntrospectionCompiler (TEnumIndex)");
                #end
                enumIntrospectionCompiler.compileEnumIndexExpression(e);
                
            case TEnumParameter(e, ef, index):
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to EnumIntrospectionCompiler (TEnumParameter)");
                #end
                enumIntrospectionCompiler.compileEnumParameterExpression(e, ef, index);
                
            case _:
                #if debug_expression_dispatcher
                trace("[XRay ExpressionDispatcher] → DELEGATING to original function");
                #end
                // Delegate everything else to original function for now
                compiler.compileElixirExpressionInternal(expr, topLevel);
        };
        
        #if debug_expression_dispatcher
        trace('[XRay ExpressionDispatcher] Generated result: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        trace("[XRay ExpressionDispatcher] EXPRESSION COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Future implementation will route to specialized compilers:
     * 
     * public function compileExpression(expr: TypedExpr, topLevel: Bool = false): Null<String> {
     *     return switch (expr.expr) {
     *         case TConst(constant):
     *             literalCompiler.compileConstant(constant);
     *             
     *         case TLocal(v):
     *             variableCompiler.compileLocalVariable(v, expr);
     *             
     *         case TBinop(op, e1, e2):
     *             operatorCompiler.compileBinaryOperation(op, e1, e2);
     *             
     *         case TUnop(op, postFix, e):
     *             operatorCompiler.compileUnaryOperation(op, postFix, e);
     *             
     *         case TIf(econd, eif, eelse):
     *             controlFlowCompiler.compileIfExpression(econd, eif, eelse);
     *             
     *         case TSwitch(e, cases, edef):
     *             controlFlowCompiler.compileSwitchExpression(e, cases, edef);
     *             
     *         case TTry(e, catches):
     *             controlFlowCompiler.compileTryExpression(e, catches);
     *             
     *         case TBlock(el):
     *             blockCompiler.compileBlock(el, topLevel);
     *             
     *         case TArray(el):
     *             dataStructureCompiler.compileArray(el);
     *             
     *         case TObjectDecl(fields):
     *             dataStructureCompiler.compileObjectDeclaration(fields);
     *             
     *         case TCall(e, el):
     *             methodCallCompiler.compileMethodCall(e, el);
     *             
     *         case TField(e, fa):
     *             // Field access - delegate to appropriate compiler based on context
     *             compileFieldAccess(e, fa);
     *             
     *         case _:
     *             // Unknown expression types
     *             handleUnknownExpression(expr);
     *     }
     * }
     */
}

#end