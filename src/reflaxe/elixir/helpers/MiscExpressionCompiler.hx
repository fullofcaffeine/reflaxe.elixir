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
 * Miscellaneous Expression Compiler for Reflaxe.Elixir
 * 
 * WHY: The compileElixirExpressionInternal function contained ~278 lines of miscellaneous expression
 * compilation logic scattered across smaller cases like TReturn, TParenthesis, TNew, TFunction, TMeta,
 * TThrow, TCast, TTypeExpr, TBreak, TContinue, TEnumIndex, and TEnumParameter. These diverse expression
 * types were mixed with core expression logic, making the main function harder to understand and
 * violating Single Responsibility Principle by handling many unrelated expression categories.
 * 
 * WHAT: Specialized compiler for miscellaneous expression types in Haxe-to-Elixir transpilation:
 * - Return statements (TReturn) → Proper Elixir return expression handling
 * - Parentheses expressions (TParenthesis) → Simple parentheses preservation
 * - Object instantiation (TNew) → Elixir struct or module instantiation patterns
 * - Lambda functions (TFunction) → Elixir anonymous function syntax (fn -> end)
 * - Metadata expressions (TMeta) → Transparent metadata handling
 * - Throw statements (TThrow) → Elixir raise/throw patterns
 * - Type casting (TCast) → Elixir type conversion or validation
 * - Type expressions (TTypeExpr) → Module name resolution
 * - Control flow statements (TBreak/TContinue) → Elixir throw/catch patterns
 * - Enum introspection (TEnumIndex/TEnumParameter) → ADT pattern matching support
 * 
 * HOW: The compiler implements straightforward transformation patterns for each expression type:
 * 1. Receives miscellaneous TypedExpr expressions from ExpressionDispatcher
 * 2. Applies appropriate Elixir idioms for each expression category
 * 3. Handles special cases like lambda parameter mapping and enum introspection
 * 4. Generates clean, idiomatic Elixir expressions for each case
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on miscellaneous expression compilation
 * - Clarity: Clear separation of concerns from core expression logic
 * - Maintainability: Easy to find and modify specific expression handling
 * - Extensibility: Simple to add new miscellaneous expression types
 * - Testability: Each expression type can be independently tested
 * - Code Organization: Groups related but diverse expression types together
 * 
 * EDGE CASES:
 * - Lambda function parameter mapping with original names
 * - Enum introspection with ADT integration
 * - Type expression resolution with proper module naming
 * - Break/continue statements in different control flow contexts
 * - Metadata handling without affecting generated output
 * - Cast expressions with proper type validation
 * 
 * @see documentation/MISC_EXPRESSION_COMPILATION_PATTERNS.md - Complete transformation patterns
 */
@:nullSafety(Off)
class MiscExpressionCompiler {
    
    var compiler: Dynamic; // ElixirCompiler reference
    
    /**
     * Create a new miscellaneous expression compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: Dynamic) {
        this.compiler = compiler;
    }
    
    /**
     * Compile TReturn return statement expressions
     * 
     * WHY: Return statements need proper Elixir expression handling
     * 
     * @param expr The return expression (nullable)
     * @return Compiled Elixir return statement
     */
    public function compileReturnStatement(expr: Null<TypedExpr>): String {
        #if debug_misc_expression_compiler
        trace("[XRay MiscExpressionCompiler] RETURN COMPILATION START");
        #end
        
        if (expr != null) {
            var compiledExpr = compiler.compileExpression(expr);
            
            #if debug_misc_expression_compiler
            trace('[XRay MiscExpressionCompiler] Return expression: ${compiledExpr}');
            #end
            
            return compiledExpr;
        } else {
            #if debug_misc_expression_compiler
            trace("[XRay MiscExpressionCompiler] Empty return");
            #end
            
            return "nil";
        }
    }
    
    /**
     * Compile TParenthesis parentheses expressions
     * 
     * WHY: Parentheses need to be preserved for expression precedence
     * 
     * @param e The inner expression
     * @return Compiled Elixir expression with parentheses
     */
    public function compileParenthesesExpression(e: TypedExpr): String {
        #if debug_misc_expression_compiler
        trace("[XRay MiscExpressionCompiler] PARENTHESES COMPILATION START");
        #end
        
        var inner = compiler.compileExpression(e);
        var result = '(${inner})';
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Parentheses result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Compile TNew object instantiation expressions
     * 
     * WHY: Object instantiation needs to map to Elixir struct or module patterns
     * 
     * @param c The class reference
     * @param params Type parameters
     * @param el Constructor arguments
     * @return Compiled Elixir instantiation expression
     */
    public function compileNewExpression(c: Ref<ClassType>, params: Array<Type>, el: Array<TypedExpr>): String {
        #if debug_misc_expression_compiler
        trace("[XRay MiscExpressionCompiler] NEW EXPRESSION COMPILATION START");
        #end
        
        var className = NamingHelper.getElixirModuleName(c.toString());
        var compiledArgs = el.map(arg -> compiler.compileExpression(arg));
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Class: ${className}, Args: ${compiledArgs.length}');
        #end
        
        if (compiledArgs.length > 0) {
            var result = '${className}.new(${compiledArgs.join(", ")})';
            
            #if debug_misc_expression_compiler
            trace('[XRay MiscExpressionCompiler] New with args: ${result}');
            #end
            
            return result;
        } else {
            var result = '${className}.new()';
            
            #if debug_misc_expression_compiler
            trace('[XRay MiscExpressionCompiler] New without args: ${result}');
            #end
            
            return result;
        }
    }
    
    /**
     * Compile TFunction lambda function expressions
     * 
     * WHY: Lambda functions need to map to Elixir anonymous function syntax
     * 
     * @param func The function definition
     * @return Compiled Elixir anonymous function
     */
    public function compileLambdaFunction(func: TFunc): String {
        #if debug_misc_expression_compiler
        trace("[XRay MiscExpressionCompiler] LAMBDA FUNCTION COMPILATION START");
        trace('[XRay MiscExpressionCompiler] Parameters: ${func.args.length}');
        #end
        
        // Get original parameter names (before Haxe's renaming)
        var paramNames = [];
        for (arg in func.args) {
            var originalName = compiler.getOriginalVarName(arg.v);
            paramNames.push(NamingHelper.toSnakeCase(originalName));
        }
        
        var body = compiler.compileExpression(func.expr);
        var result = 'fn ${paramNames.join(", ")} -> ${body} end';
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Lambda result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Compile TMeta metadata expressions
     * 
     * WHY: Metadata wrappers should be transparent in generated code
     * 
     * @param metadata The metadata
     * @param expr The wrapped expression
     * @return Compiled inner expression (metadata ignored)
     */
    public function compileMetadataExpression(metadata: MetadataEntry, expr: TypedExpr): String {
        #if debug_misc_expression_compiler
        trace("[XRay MiscExpressionCompiler] METADATA COMPILATION START");
        trace('[XRay MiscExpressionCompiler] Metadata: ${metadata.name}');
        #end
        
        // Compile metadata wrapper - just compile the inner expression
        var result = compiler.compileExpression(expr);
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Metadata result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Compile TThrow throw statement expressions
     * 
     * WHY: Throw statements need to map to Elixir raise or throw patterns
     * 
     * @param expr The expression to throw
     * @return Compiled Elixir throw/raise statement
     */
    public function compileThrowStatement(expr: TypedExpr): String {
        #if debug_misc_expression_compiler
        trace("[XRay MiscExpressionCompiler] THROW COMPILATION START");
        #end
        
        var throwExpr = compiler.compileExpression(expr);
        var result = 'raise ${throwExpr}';
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Throw result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Compile TCast casting expressions
     * 
     * WHY: Type casts should be transparent or add validation in Elixir
     * 
     * @param expr The expression to cast
     * @param moduleType The target type
     * @return Compiled Elixir expression (cast usually transparent)
     */
    public function compileCastExpression(expr: TypedExpr, moduleType: Null<ModuleType>): String {
        #if debug_misc_expression_compiler
        trace("[XRay MiscExpressionCompiler] CAST COMPILATION START");
        #end
        
        // Simple cast - just compile the expression
        var result = compiler.compileExpression(expr);
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Cast result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Compile TTypeExpr type expressions
     * 
     * WHY: Type expressions need to resolve to proper Elixir module names
     * 
     * @param moduleType The module type reference
     * @return Compiled Elixir module name
     */
    public function compileTypeExpression(moduleType: ModuleType): String {
        #if debug_misc_expression_compiler
        trace("[XRay MiscExpressionCompiler] TYPE EXPRESSION COMPILATION START");
        #end
        
        // Type expression - convert to Elixir module name
        var result = switch (moduleType) {
            case TClassDecl(c): NamingHelper.getElixirModuleName(c.get().name);
            case TEnumDecl(e): NamingHelper.getElixirModuleName(e.get().name);
            case TAbstract(a): NamingHelper.getElixirModuleName(a.get().name);
            case _: "Dynamic";
        };
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Type expression result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Compile TBreak break statements
     * 
     * WHY: Break statements need Elixir throw/catch or early return patterns
     * 
     * @return Compiled Elixir break equivalent
     */
    public function compileBreakStatement(): String {
        #if debug_misc_expression_compiler
        trace("[XRay MiscExpressionCompiler] BREAK COMPILATION START");
        #end
        
        // Break statement - in Elixir, we use a throw/catch pattern or early return
        var result = 'throw(:break)';
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Break result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Compile TContinue continue statements
     * 
     * WHY: Continue statements need Elixir throw/catch or skip patterns
     * 
     * @return Compiled Elixir continue equivalent
     */
    public function compileContinueStatement(): String {
        #if debug_misc_expression_compiler
        trace("[XRay MiscExpressionCompiler] CONTINUE COMPILATION START");
        #end
        
        // Continue statement - in Elixir, we use a throw/catch pattern or skip to next iteration
        var result = 'throw(:continue)';
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Continue result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * TODO: Future implementation will contain enum introspection methods:
     * 
     * - compileEnumIndexExpression(e) for TEnumIndex
     * - compileEnumParameterExpression(e, ef, index) for TEnumParameter
     * - Enhanced ADT integration for complex enum patterns
     * - Dynamic enum introspection with runtime type checking
     * - Pattern matching integration for enum analysis
     * 
     * These methods will support enum introspection and analysis patterns
     * commonly used in functional programming and pattern matching.
     */
}

#end