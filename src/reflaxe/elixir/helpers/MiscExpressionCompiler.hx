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
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    
    /**
     * Create a new miscellaneous expression compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
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
        if (expr != null) {
            trace('[XRay MiscExpressionCompiler] Return expr type: ${expr.expr}');
        }
        #end
        
        if (expr != null) {
            // CRITICAL FIX: Handle TReturn(TSwitch) pattern to generate direct value-returning case
            // This prevents temp variable shadowing in Elixir's scoped case expressions
            switch (expr.expr) {
                case TSwitch(switchExpr, cases, defaultExpr):
                    #if debug_misc_expression_compiler
                    trace("[XRay MiscExpressionCompiler] ✓ DETECTED TReturn(TSwitch) - compiling as value-returning case");
                    #end
                    
                    // Mark that we're compiling a switch as a value expression
                    var wasCompilingCaseArm = compiler.isCompilingCaseArm;
                    compiler.isCompilingCaseArm = true;
                    
                    // Compile the switch directly as a value-returning expression
                    var result = compiler.compileSwitchExpression(switchExpr, cases, defaultExpr);
                    
                    // Restore context
                    compiler.isCompilingCaseArm = wasCompilingCaseArm;
                    
                    return result;
                    
                case _:
                    // Normal return statement compilation
                    var compiledExpr = compiler.compileExpression(expr);
                    
                    #if debug_misc_expression_compiler
                    trace('[XRay MiscExpressionCompiler] Return expression: ${compiledExpr}');
                    #end
                    
                    return compiledExpr;
            }
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
     * WHY: Parentheses should only be added when necessary for operator precedence or clarity.
     *      Excessive parentheses make generated Elixir code hard to read and unidiomatic.
     * 
     * WHAT: Smart parenthesization that analyzes the inner expression type to determine
     *       if parentheses are actually needed in the Elixir output.
     * 
     * HOW:
     * 1. Compile the inner expression
     * 2. Analyze if the expression needs parentheses based on context
     * 3. Only add parentheses when they improve readability or are required for precedence
     * 
     * @param e The inner expression
     * @return Compiled Elixir expression with smart parenthesization
     */
    public function compileParenthesesExpression(e: TypedExpr): String {
        #if debug_misc_expression_compiler
        trace("[XRay MiscExpressionCompiler] SMART PARENTHESES COMPILATION START");
        #end
        
        var inner = compiler.compileExpression(e);
        
        // SMART PARENTHESIZATION: Only add parentheses when they're actually needed
        var needsParentheses = switch (e.expr) {
            // Simple expressions don't need parentheses
            case TLocal(_) | TConst(_) | TField(_, _):
                #if debug_misc_expression_compiler
                trace("[XRay MiscExpressionCompiler] ✓ SIMPLE EXPRESSION - skipping parentheses");
                #end
                false;
                
            // Function calls don't need parentheses unless in complex contexts
            case TCall(_, _):
                #if debug_misc_expression_compiler
                trace("[XRay MiscExpressionCompiler] ✓ FUNCTION CALL - skipping parentheses");
                #end
                false;
                
            // Case expressions are self-delimiting, don't need outer parentheses
            case TSwitch(_, _, _):
                #if debug_misc_expression_compiler
                trace("[XRay MiscExpressionCompiler] ✓ CASE EXPRESSION - skipping parentheses");
                #end
                false;
                
            // Block expressions are self-delimiting
            case TBlock(_):
                #if debug_misc_expression_compiler
                trace("[XRay MiscExpressionCompiler] ✓ BLOCK EXPRESSION - skipping parentheses");
                #end
                false;
                
            // Array literals are self-delimiting
            case TArrayDecl(_):
                #if debug_misc_expression_compiler
                trace("[XRay MiscExpressionCompiler] ✓ ARRAY LITERAL - skipping parentheses");
                #end
                false;
                
            // Object literals are self-delimiting
            case TObjectDecl(_):
                #if debug_misc_expression_compiler
                trace("[XRay MiscExpressionCompiler] ✓ OBJECT LITERAL - skipping parentheses");
                #end
                false;
                
            // Binary operations might need parentheses for precedence
            case TBinop(_, _, _):
                #if debug_misc_expression_compiler
                trace("[XRay MiscExpressionCompiler] ⚠️ BINARY OPERATION - checking if parentheses needed");
                #end
                // For now, be conservative and keep them for binary operations
                // TODO: More sophisticated precedence analysis
                true;
                
            // Complex expressions might need parentheses
            case TIf(_, _, _) | TFor(_, _, _) | TWhile(_, _, _) | TTry(_, _):
                #if debug_misc_expression_compiler
                trace("[XRay MiscExpressionCompiler] ⚠️ COMPLEX EXPRESSION - keeping parentheses");
                #end
                true;
                
            // Default: be conservative and keep parentheses for unknown expression types
            case _:
                #if debug_misc_expression_compiler
                trace("[XRay MiscExpressionCompiler] ? UNKNOWN EXPRESSION TYPE - keeping parentheses for safety");
                trace('[XRay MiscExpressionCompiler] Expression type: ${Type.enumConstructor(e.expr)}');
                #end
                true;
        };
        
        var result = if (needsParentheses) {
            '(${inner})';
        } else {
            inner;
        };
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Smart parentheses result: ${result}');
        trace("[XRay MiscExpressionCompiler] SMART PARENTHESES COMPILATION END");
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
        
        // Use just the class name, not the full package path
        // This matches how ClassCompiler generates module names
        var classType = c.get();
        var className = NamingHelper.getElixirModuleName(classType.name);
        var compiledArgs = el.map(arg -> compiler.compileExpression(arg));
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Class: ${className}, Args: ${compiledArgs.length}');
        #end
        
        // Check if this class has a custom new() method defined
        var hasCustomNew = false;
        
        // Look for a static new() method in the class
        for (field in classType.statics.get()) {
            if (field.name == "new") {
                hasCustomNew = true;
                break;
            }
        }
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Has custom new(): ${hasCustomNew}');
        #end
        
        // If there's a custom new() method, call it
        if (hasCustomNew) {
            if (compiledArgs.length > 0) {
                var result = '${className}.new(${compiledArgs.join(", ")})';
                
                #if debug_misc_expression_compiler
                trace('[XRay MiscExpressionCompiler] Custom new with args: ${result}');
                #end
                
                return result;
            } else {
                var result = '${className}.new()';
                
                #if debug_misc_expression_compiler
                trace('[XRay MiscExpressionCompiler] Custom new without args: ${result}');
                #end
                
                return result;
            }
        }
        
        // For structs without custom new(), use Elixir struct literal syntax or call new()
        // The standard library classes define new() methods, so we call them
        if (compiledArgs.length > 0) {
            var result = '${className}.new(${compiledArgs.join(", ")})';
            
            #if debug_misc_expression_compiler
            trace('[XRay MiscExpressionCompiler] Standard new with args: ${result}');
            #end
            
            return result;
        } else {
            // For classes like JsonPrinter that define their own new(), we call it
            var result = '${className}.new()';
            
            #if debug_misc_expression_compiler
            trace('[XRay MiscExpressionCompiler] Standard new without args: ${result}');
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
        
        // Check for array operation metadata from our preprocessor
        if (metadata.name.startsWith(":elixir_enum_")) {
            var methodName = metadata.name.substring(13); // Remove ":elixir_enum_" prefix
            
            #if debug_misc_expression_compiler || debug_array_preprocessor
            trace('[XRay MiscExpressionCompiler] ✓ ARRAY OPERATION DETECTED: ${methodName}');
            #end
            
            return compileEnumOperation(methodName, expr);
        }
        
        // Default behavior - just compile the inner expression
        var result = compiler.compileExpression(expr);
        
        #if debug_misc_expression_compiler
        trace('[XRay MiscExpressionCompiler] Metadata result: ${result}');
        #end
        
        return result;
    }
    
    /**
     * COMPILE ENUM OPERATION: Generate idiomatic Elixir Enum.filter/map calls
     * 
     * WHY: Transform preprocessed array operations into clean Elixir code
     * WHAT: Extract array and lambda from metadata structure and generate Enum calls
     * HOW: Parse the TBlock structure created by ArrayOperationPreprocessor
     */
    private function compileEnumOperation(methodName: String, expr: TypedExpr): String {
        #if debug_misc_expression_compiler || debug_array_preprocessor
        trace('[XRay MiscExpressionCompiler] COMPILING ENUM OPERATION: ${methodName}');
        #end
        
        switch(expr.expr) {
            case TBlock(exprs) if (exprs.length == 2):
                var arrayExpr: Null<TypedExpr> = null;
                var lambdaExpr: Null<TypedExpr> = null;
                
                // Extract array and lambda from meta-tagged expressions
                for (e in exprs) {
                    switch(e.expr) {
                        case TMeta(meta, innerExpr):
                            if (meta.name == ":enum_array") {
                                arrayExpr = innerExpr;
                            } else if (meta.name == ":enum_lambda") {
                                lambdaExpr = innerExpr;
                            }
                        case _:
                    }
                }
                
                if (arrayExpr != null && lambdaExpr != null) {
                    var compiledArray = compiler.compileExpression(arrayExpr);
                    var compiledLambda = compiler.compileExpression(lambdaExpr);
                    
                    #if debug_misc_expression_compiler || debug_array_preprocessor
                    trace('[XRay MiscExpressionCompiler] ✓ GENERATING IDIOMATIC ELIXIR: Enum.${methodName}(${compiledArray}, ${compiledLambda})');
                    #end
                    
                    return 'Enum.${methodName}(${compiledArray}, ${compiledLambda})';
                }
            case _:
        }
        
        // Fallback - shouldn't happen if preprocessor works correctly
        #if debug_misc_expression_compiler || debug_array_preprocessor
        trace('[XRay MiscExpressionCompiler] ⚠️ FALLBACK: Could not extract array/lambda, compiling normally');
        #end
        
        return compiler.compileExpression(expr);
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
     * WHY: Type expressions need to resolve to proper Elixir module names with @:native support
     * 
     * WHAT: Transforms Haxe type references to fully-qualified Elixir module names,
     * respecting @:native annotations for framework integration (e.g., TodoLive → TodoAppWeb.TodoLive)
     * 
     * HOW: 
     * 1. Check for @:native annotation first - this overrides default naming
     * 2. Fall back to NamingHelper conversion for classes without @:native
     * 3. Ensure proper module resolution for static method calls
     * 
     * @param moduleType The module type reference
     * @return Compiled Elixir module name (fully-qualified when @:native exists)
     */
    public function compileTypeExpression(moduleType: ModuleType): String {
        #if debug_misc_expression_compiler
        trace("[XRay MiscExpressionCompiler] TYPE EXPRESSION COMPILATION START");
        #end
        
        // Type expression - convert to Elixir module name, respecting @:native annotations
        var result = switch (moduleType) {
            case TClassDecl(c):
                var classType = c.get();
                #if debug_misc_expression_compiler
                trace('[XRay MiscExpressionCompiler] Resolving class type: ${classType.name}');
                #end
                
                // First check for @:native annotation
                var nativeMeta = classType.meta.extract(":native");
                if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                    switch (nativeMeta[0].params[0].expr) {
                        case EConst(CString(nativeName, _)):
                            #if debug_misc_expression_compiler
                            trace('[XRay MiscExpressionCompiler] ✓ Using @:native annotation: ${nativeName}');
                            #end
                            
                            // Validate @:native format for common mistakes
                            if (nativeName.length == 0) {
                                haxe.macro.Context.warning('@:native annotation is empty for class ${classType.name}. Using default naming.', haxe.macro.Context.currentPos());
                                NamingHelper.getElixirModuleName(classType.name);
                            } else if (!~/^[A-Z][a-zA-Z0-9]*(\.[A-Z][a-zA-Z0-9]*)*$/.match(nativeName)) {
                                haxe.macro.Context.warning('@:native("${nativeName}") does not follow Elixir module naming convention (should be like "MyApp.MyModule") for class ${classType.name}. Using as-is.', haxe.macro.Context.currentPos());
                                nativeName;
                            } else {
                                nativeName;
                            }
                        case _:
                            #if debug_misc_expression_compiler
                            trace('[XRay MiscExpressionCompiler] ⚠ Invalid @:native format, falling back to default');
                            #end
                            haxe.macro.Context.warning('@:native parameter must be a string literal for class ${classType.name}. Example: @:native("MyApp.MyModule"). Using default naming.', haxe.macro.Context.currentPos());
                            NamingHelper.getElixirModuleName(classType.name);
                    }
                } else {
                    #if debug_misc_expression_compiler
                    trace('[XRay MiscExpressionCompiler] ⚠ No @:native found, using default naming');
                    #end
                    NamingHelper.getElixirModuleName(classType.name);
                }
                
            case TEnumDecl(e):
                var enumType = e.get();
                // Check for @:native on enums too
                var nativeMeta = enumType.meta.extract(":native");
                if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                    switch (nativeMeta[0].params[0].expr) {
                        case EConst(CString(nativeName, _)):
                            nativeName;
                        case _:
                            NamingHelper.getElixirModuleName(enumType.name);
                    }
                } else {
                    NamingHelper.getElixirModuleName(enumType.name);
                }
                
            case TAbstract(a):
                var abstractType = a.get();
                // Check for @:native on abstracts too  
                var nativeMeta = abstractType.meta.extract(":native");
                if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                    switch (nativeMeta[0].params[0].expr) {
                        case EConst(CString(nativeName, _)):
                            nativeName;
                        case _:
                            NamingHelper.getElixirModuleName(abstractType.name);
                    }
                } else {
                    NamingHelper.getElixirModuleName(abstractType.name);
                }
                
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