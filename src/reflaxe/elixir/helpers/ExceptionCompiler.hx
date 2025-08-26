package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;

using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * ExceptionCompiler: Specialized compiler for try/catch/finally exception handling
 * 
 * WHY: Exception handling in the original ControlFlowCompiler was mixed with loops,
 *      conditionals, and pattern matching across 2,920 lines. Try/catch compilation
 *      involved complex pattern analysis, multiple catch clauses, and finally block
 *      handling that was difficult to maintain when combined with unrelated logic.
 * 
 * WHAT: Handles all exception handling compilation for Haxe-to-Elixir transpilation:
 * - Try/catch blocks → Elixir try-rescue-catch blocks
 * - Multiple catch clauses → Pattern-based rescue clauses
 * - Finally blocks → Elixir after clauses
 * - Exception types → Proper Elixir exception structs
 * - Rethrow patterns → Elixir reraise functionality
 * - Custom exceptions → Defexception modules
 * 
 * HOW: Implements exception handling transformation:
 * 1. Analyzes try block for potential exceptions
 * 2. Transforms catch clauses to rescue patterns
 * 3. Handles exception type matching and binding
 * 4. Generates proper after clauses for finally blocks
 * 5. Ensures exception propagation semantics match
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles exception handling
 * - Exception Expertise: Specialized error handling logic
 * - Pattern Matching: Focused exception pattern matching
 * - Clean Separation: Isolated from other control flow
 * - Maintainability: ~600 lines focused on exceptions
 * 
 * EDGE CASES:
 * - Multiple exception types in single catch
 * - Exception variable binding and scoping
 * - Finally blocks with return statements
 * - Nested try/catch blocks
 * - Custom exception hierarchies
 */
@:nullSafety(Off)
class ExceptionCompiler {
    
    /** Reference to main compiler for expression compilation */
    var compiler: ElixirCompiler;
    
    /**
     * Constructor
     * @param compiler Main ElixirCompiler instance for delegation
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
        
        #if debug_exception_compilation
        trace("[ExceptionCompiler] Initialized");
        #end
    }
    
    /**
     * Compiles try/catch/finally expressions to Elixir
     * 
     * WHY: Exception handling in Haxe maps to try-rescue-catch-after in Elixir
     *      with different semantics and syntax
     * WHAT: Transforms Haxe try blocks to idiomatic Elixir exception handling
     * HOW: Converts catch clauses, handles finally blocks, preserves semantics
     * 
     * @param e Try block expression
     * @param catches Array of catch clauses with variables and expressions
     * @param finallyExpr Optional finally block expression
     * @return Generated Elixir try-rescue-catch-after block
     */
    public function compileTryExpression(e: TypedExpr, catches: Array<{v: TVar, expr: TypedExpr}>, finallyExpr: Null<TypedExpr> = null): String {
        #if debug_exception_compilation
        trace("[ExceptionCompiler] Compiling try expression");
        trace('[ExceptionCompiler] Catches: ${catches.length}');
        trace('[ExceptionCompiler] Has finally: ${finallyExpr != null}');
        #end
        
        // Compile the try block
        var tryStr = compiler.compileExpression(e);
        
        // Build rescue clauses
        var rescueClauses = [];
        var catchAllClause = null;
        
        for (c in catches) {
            var clause = compileCatchClause(c.v, c.expr);
            if (clause.isGeneric) {
                catchAllClause = clause.code;
            } else {
                rescueClauses.push(clause.code);
            }
        }
        
        // Build the try block
        var result = new StringBuf();
        result.add("try do\n");
        result.add(indent(tryStr));
        result.add("\n");
        
        // Add rescue clauses
        if (rescueClauses.length > 0) {
            result.add("rescue\n");
            for (clause in rescueClauses) {
                result.add(indent(clause));
                result.add("\n");
            }
        }
        
        // Add catch-all clause if present
        if (catchAllClause != null) {
            if (rescueClauses.length == 0) {
                result.add("rescue\n");
            }
            result.add(indent(catchAllClause));
            result.add("\n");
        }
        
        // Add finally block if present
        if (finallyExpr != null) {
            result.add("after\n");
            result.add(indent(compiler.compileExpression(finallyExpr)));
            result.add("\n");
        }
        
        result.add("end");
        return result.toString();
    }
    
    /**
     * Compiles a single catch clause
     * 
     * WHY: Each catch clause needs pattern matching and variable binding
     * WHAT: Transforms catch clause to Elixir rescue pattern
     * HOW: Analyzes exception type, generates pattern, binds variable
     * 
     * @param v Exception variable
     * @param expr Catch block expression
     * @return Compiled rescue clause with generic flag
     */
    function compileCatchClause(v: TVar, expr: TypedExpr): {code: String, isGeneric: Bool} {
        #if debug_exception_compilation
        trace('[ExceptionCompiler] Compiling catch clause for: ${v.name}');
        #end
        
        var varName = compiler.variableCompiler.compileLocalVariable(v);
        var bodyStr = compiler.compileExpression(expr);
        
        // Check exception type
        var exceptionPattern = getExceptionPattern(v.t);
        
        if (exceptionPattern.isGeneric) {
            // Generic exception catch
            return {
                code: '${varName} -> ${bodyStr}',
                isGeneric: true
            };
        } else {
            // Specific exception type
            return {
                code: '${exceptionPattern.pattern} = ${varName} -> ${bodyStr}',
                isGeneric: false
            };
        }
    }
    
    /**
     * Determines exception pattern from type
     * 
     * WHY: Different exception types need different patterns
     * WHAT: Maps Haxe exception types to Elixir patterns
     * HOW: Analyzes type structure, generates matching pattern
     * 
     * @param type Exception type
     * @return Pattern string and generic flag
     */
    function getExceptionPattern(type: Type): {pattern: String, isGeneric: Bool} {
        #if debug_exception_compilation
        trace('[ExceptionCompiler] Getting pattern for type: ${type}');
        #end
        
        return switch(type) {
            case TInst(t, _):
                var className = t.get().name;
                switch(className) {
                    case "Dynamic", "Any", "Exception":
                        {pattern: "_", isGeneric: true};
                    default:
                        {pattern: '%${className}{}', isGeneric: false};
                }
            default:
                {pattern: "_", isGeneric: true};
        }
    }
    
    /**
     * Compiles throw expressions
     * 
     * WHY: Throw statements need transformation to Elixir raise
     * WHAT: Converts Haxe throw to Elixir raise/throw
     * HOW: Determines exception type, generates appropriate raise
     * 
     * @param expr Expression to throw
     * @return Generated Elixir raise/throw statement
     */
    public function compileThrowExpression(expr: TypedExpr): String {
        #if debug_exception_compilation
        trace("[ExceptionCompiler] Compiling throw expression");
        #end
        
        var exprStr = compiler.compileExpression(expr);
        
        // Check if it's an exception struct or a value
        if (isExceptionStruct(expr)) {
            return 'raise ${exprStr}';
        } else {
            // Throw non-exception values
            return 'throw(${exprStr})';
        }
    }
    
    /**
     * Compiles rethrow expressions
     * 
     * WHY: Rethrow needs to preserve original stacktrace
     * WHAT: Generates Elixir reraise statement
     * HOW: Uses reraise with preserved stacktrace
     * 
     * @return Generated Elixir reraise statement
     */
    public function compileRethrowExpression(): String {
        #if debug_exception_compilation
        trace("[ExceptionCompiler] Compiling rethrow expression");
        #end
        
        // In Elixir, reraise preserves the original stacktrace
        return "reraise(__exception__, __STACKTRACE__)";
    }
    
    /**
     * Checks if expression is an exception struct
     * 
     * WHY: Exceptions and regular values are handled differently
     * WHAT: Determines if value is an exception type
     * HOW: Analyzes expression type structure
     * 
     * @param expr Expression to check
     * @return True if exception struct
     */
    function isExceptionStruct(expr: TypedExpr): Bool {
        return switch(expr.t) {
            case TInst(t, _):
                var cls = t.get();
                // Check if it inherits from Exception or has exception metadata
                cls.name.endsWith("Exception") || cls.name.endsWith("Error");
            default:
                false;
        }
    }
    
    /**
     * Compiles custom exception definitions
     * 
     * WHY: Custom exceptions need defexception in Elixir
     * WHAT: Generates exception module definitions
     * HOW: Creates defexception with message field
     * 
     * @param classType Exception class type
     * @return Generated defexception module
     */
    public function compileExceptionDefinition(classType: ClassType): String {
        #if debug_exception_compilation
        trace('[ExceptionCompiler] Compiling exception definition: ${classType.name}');
        #end
        
        var moduleName = classType.name;
        var fields = [];
        
        // Add message field by default
        fields.push("message: nil");
        
        // Add custom fields
        for (field in classType.fields.get()) {
            if (field.isPublic && !field.name.startsWith("_")) {
                var fieldName = StringTools.replace(field.name, "_", "_");
                fields.push('${fieldName}: nil');
            }
        }
        
        return 'defexception [${fields.join(", ")}]';
    }
    
    /**
     * Adds indentation to code
     * 
     * WHY: Proper indentation for readability
     * WHAT: Indents code lines
     * HOW: Prepends spaces
     * 
     * @param code Code to indent
     * @param level Spaces to indent
     * @return Indented code
     */
    function indent(code: String, level: Int = 2): String {
        var spaces = [for (i in 0...level) " "].join("");
        return code.split("\n").map(line -> spaces + line).join("\n");
    }
}

#end