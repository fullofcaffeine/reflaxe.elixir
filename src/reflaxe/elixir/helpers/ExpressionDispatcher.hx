package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;import haxe.macro.Expr;
import reflaxe.elixir.ElixirCompiler;import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;
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
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    
    // Specialized compilers (will be created as we extract more functionality)
    public var literalCompiler: LiteralCompiler;
    public var conditionalCompiler: ConditionalCompiler;
    public var patternMatchingCompiler: PatternMatchingCompiler;
    public var exceptionCompiler: ExceptionCompiler;
    var operatorCompiler: OperatorCompiler;
    // TODO: Uncomment as compilers are extracted:
    public var variableCompiler: VariableCompiler;
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
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
        
        // CRITICAL: Reuse existing instances from main compiler to maintain state consistency
        // Using duplicate instances causes state inconsistency bugs!
        
        // Reuse instances that exist in main compiler
        this.patternMatchingCompiler = compiler.patternMatchingCompiler;
        this.methodCallCompiler = compiler.methodCallCompiler;
        this.variableCompiler = compiler.variableCompiler;
        
        // Create instances that don't exist in main compiler
        // TODO: Consider moving these to main compiler if they need shared state
        this.literalCompiler = new LiteralCompiler(compiler);
        this.conditionalCompiler = new ConditionalCompiler(compiler);
        this.exceptionCompiler = new ExceptionCompiler(compiler);
        this.operatorCompiler = new OperatorCompiler(compiler, this.literalCompiler);
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
        // trace("[XRay ExpressionDispatcher] EXPRESSION COMPILATION START");
        // trace('[XRay ExpressionDispatcher] Expression type: ${expr.expr}');
        // trace('[XRay ExpressionDispatcher] Top level: ${topLevel}');
        #end
        
        // NOTE: Parent expression tracking removed - orphan detection moved to TBlock level
        
        // Gradual extraction - dispatch to specialized compilers
        var result = switch (expr.expr) {
            case TConst(constant):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to LiteralCompiler");
                #end
                literalCompiler.compileConstant(constant);
                
            case TBlock(el):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ Compiling TBlock directly");
                #end
                // Simple block compilation - just compile expressions in sequence
                if (el.length == 0) {
                    "nil";
                } else if (el.length == 1) {
                    compileExpression(el[0], topLevel);
                } else {
                    var expressions = [];
                    for (expr in el) {
                        var compiled = compileExpression(expr, false);
                        if (compiled != null && compiled.length > 0) {
                            expressions.push(compiled);
                        }
                    }
                    expressions.join(topLevel ? "\n\n" : "\n");
                }
                
            case TIf(econd, eif, eelse):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to ConditionalCompiler (TIf)");
                // trace("[XRay ExpressionDispatcher] TIf condition: " + Type.enumConstructor(econd.expr));
                // trace("[XRay ExpressionDispatcher] TIf then branch: " + Type.enumConstructor(eif.expr));
                if (eelse != null) {
                    // trace("[XRay ExpressionDispatcher] TIf else branch: " + Type.enumConstructor(eelse.expr));
                    
                    // Check if this is an array ternary pattern that should use inline form
                    // Handle both direct TArrayDecl and TArrayDecl inside TBinop assignment operations
                    var isThenArray = switch(eif.expr) { 
                        case TArrayDecl(_): true; 
                        case TBinop(OpAssign, _, e): switch(e.expr) { case TArrayDecl(_): true; case _: false; };
                        case _: false; 
                    };
                    var isElseArray = switch(eelse.expr) { 
                        case TArrayDecl(_): true; 
                        case TBinop(OpAssign, _, e): switch(e.expr) { case TArrayDecl(_): true; case _: false; };
                        case _: false; 
                    };
                    
                    if (isThenArray && isElseArray) {
                        // trace("[XRay ExpressionDispatcher] ⚠️ ARRAY TERNARY DETECTED IN EXPRESSION DISPATCHER!");
                        // trace("[XRay ExpressionDispatcher] This should trigger inline if generation");
                        // trace("[XRay ExpressionDispatcher] Then branch type: " + Type.enumConstructor(eif.expr));
                        // trace("[XRay ExpressionDispatcher] Else branch type: " + Type.enumConstructor(eelse.expr));
                    }
                } else {
                    // trace("[XRay ExpressionDispatcher] TIf else branch: null");
                }
                #end
                conditionalCompiler.compileIfExpression(econd, eif, eelse);
                
            case TSwitch(e, cases, edef):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to PatternMatchingCompiler (TSwitch)");
                #end
                patternMatchingCompiler.compileSwitchExpression(e, cases, edef);
                
            case TWhile(econd, ebody, normalWhile):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to UnifiedLoopCompiler (TWhile)");
                #end
                compiler.unifiedLoopCompiler.compileWhileLoop(econd, ebody, normalWhile);
                
            case TFor(tvar, iterExpr, blockExpr):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to UnifiedLoopCompiler (TFor)");
                #end
                compiler.unifiedLoopCompiler.compileForLoop(tvar, iterExpr, blockExpr);
                
            case TTry(e, catches):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to ExceptionCompiler (TTry)");
                #end
                exceptionCompiler.compileTryExpression(e, catches);
                
            case TBinop(op, e1, e2):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to OperatorCompiler (TBinop)");
                #end
                operatorCompiler.compileBinaryOperation(op, e1, e2);
                
            case TUnop(op, postFix, e):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to OperatorCompiler (TUnop)");
                #end
                operatorCompiler.compileUnaryOperation(op, postFix, e);
                
            case TArrayDecl(el):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to DataStructureCompiler (TArrayDecl)");
                #end
                dataStructureCompiler.compileArrayLiteral(el);
                
            case TObjectDecl(fields):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to DataStructureCompiler (TObjectDecl)");
                #end
                dataStructureCompiler.compileObjectDeclaration(fields);
                
            case TArray(e1, e2):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to DataStructureCompiler (TArray)");
                #end
                dataStructureCompiler.compileArrayIndexing(e1, e2);
                
            case TLocal(v):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to VariableCompiler (TLocal)");
                #end
                #if debug_orphan_elimination
                // trace('[XRay ExpressionDispatcher] TLocal dispatch - variable: ${v.name}');
                // NOTE: Parent tracking debug removed - orphan detection moved to TBlock level
                #end
                variableCompiler.compileLocalVariable(v);
                
            case TVar(tvar, expr):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to VariableCompiler (TVar)");
                #end
                variableCompiler.compileVariableDeclaration(tvar, expr);
                
            case TField(e, fa):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to FieldAccessCompiler (TField)");
                #end
                fieldAccessCompiler.compileFieldAccess(e, fa, expr);
                
            case TCall(e, el):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ Processing TCall");
                #end
                
                // CRITICAL FIX: Check for __elixir__ injection BEFORE delegating to MethodCallCompiler
                // This prevents double-wrapping issue where injection is processed as regular call
                switch(e.expr) {
                    case TIdent(id) if (id == "__elixir__" && compiler.options.targetCodeInjectionName == "__elixir__"):
                        #if debug_expression_dispatcher
                        // trace("[XRay ExpressionDispatcher] ✓ Detected __elixir__ injection in TCall - letting parent handle it");
                        #end
                        // Let the parent's injection detection handle this
                        // The parent (DirectToStringCompiler) will detect TCall(TIdent("__elixir__"), args)
                        // and return the properly injected code
                        var parentResult = compiler.compileExpression(expr, topLevel);
                        if (parentResult != null) {
                            return parentResult;
                        }
                        // If parent didn't handle it (shouldn't happen), fall through
                        
                    case _:
                        // Not an injection call, proceed normally
                }
                
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MethodCallCompiler (TCall)");
                #end
                methodCallCompiler.compileCallExpression(e, el);
                
            case TReturn(e):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TReturn)");
                #end
                miscExpressionCompiler.compileReturnStatement(e);
                
            case TParenthesis(e):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TParenthesis)");
                #end
                miscExpressionCompiler.compileParenthesesExpression(e);
                
            case TNew(c, params, el):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TNew)");
                #end
                miscExpressionCompiler.compileNewExpression(c, params, el);
                
            case TFunction(func):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TFunction)");
                #end
                miscExpressionCompiler.compileLambdaFunction(func);
                
            case TMeta(metadata, expr):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TMeta)");
                #end
                miscExpressionCompiler.compileMetadataExpression(metadata, expr);
                
            case TThrow(e):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TThrow)");
                #end
                miscExpressionCompiler.compileThrowStatement(e);
                
            case TCast(e, moduleType):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TCast)");
                #end
                miscExpressionCompiler.compileCastExpression(e, moduleType);
                
            case TTypeExpr(moduleType):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TTypeExpr)");
                #end
                miscExpressionCompiler.compileTypeExpression(moduleType);
                
            case TBreak:
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TBreak)");
                #end
                miscExpressionCompiler.compileBreakStatement();
                
            case TContinue:
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to MiscExpressionCompiler (TContinue)");
                #end
                miscExpressionCompiler.compileContinueStatement();
                
            case TEnumIndex(e):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to EnumIntrospectionCompiler (TEnumIndex)");
                #end
                enumIntrospectionCompiler.compileEnumIndexExpression(e);
                
            case TEnumParameter(e, ef, index):
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] ✓ DISPATCHING to EnumIntrospectionCompiler (TEnumParameter)");
                #end
                enumIntrospectionCompiler.compileEnumParameterExpression(e, ef, index);
                
            case _:
                #if debug_expression_dispatcher
                // trace("[XRay ExpressionDispatcher] → UNHANDLED EXPRESSION TYPE!");
                // trace('[XRay ExpressionDispatcher] Expression type: ${expr.expr}');
                #end
                
                // PRODUCTION FALLBACK: Handle remaining expression types directly
                // This avoids circular delegation and ensures proper topLevel handling
                switch (expr.expr) {
                    // Handle remaining expression types that don't have specialized compilers yet
                    case TIdent(name): name;
                    case TConst(TThis): "this";  
                    case TConst(TSuper): "super";
                    case TConst(TNull): "nil";
                    default:
                        // Final fallback for truly unknown expressions
                        #if debug_expression_dispatcher
                        // trace('[XRay ExpressionDispatcher] → FINAL FALLBACK for ${expr.expr}');
                        #end
                        "nil"; // Safe fallback instead of circular call
                }
        };
        
        #if debug_expression_dispatcher
        // trace('[XRay ExpressionDispatcher] Generated result: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        // trace("[XRay ExpressionDispatcher] EXPRESSION COMPILATION END");
        #end
        
        // NOTE: Parent expression tracking removed - orphan detection moved to TBlock level
        
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
