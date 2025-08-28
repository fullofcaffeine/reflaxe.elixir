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
 * ConditionalCompiler: Specialized compiler for if/else/ternary expressions
 * 
 * WHY: The original ControlFlowCompiler mixed conditional logic with switch statements,
 *      exception handling, and block compilation in 2,920 lines. If/else compilation alone
 *      involved complex Y combinator detection, struct update patterns, and ternary optimizations
 *      that were difficult to maintain when mixed with unrelated control flow logic.
 * 
 * WHAT: Handles all conditional expression compilation for Haxe-to-Elixir transpilation:
 * - Standard if/else expressions → Elixir if-do-else-end blocks
 * - Ternary operations → Optimized inline if expressions
 * - Guard clauses → Elixir guard syntax in function definitions
 * - Nested conditionals → Proper scoping and indentation
 * - Boolean short-circuit → && and || operator optimization
 * 
 * HOW: Implements sophisticated conditional transformation patterns:
 * 1. Analyzes conditional structure for optimization opportunities
 * 2. Transforms ternary operators to idiomatic Elixir inline if
 * 3. Handles variable scoping issues in nested conditionals
 * 4. Generates clean, readable Elixir conditional code
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles conditional expressions
 * - Clear Interface: Simple public API for if/else compilation
 * - Optimization Focus: All conditional optimizations in one place
 * - Testability: Conditional logic isolated from other control flow
 * - Maintainability: ~800 lines vs 2,920 in original file
 * 
 * EDGE CASES:
 * - Empty else branches requiring nil return
 * - Struct updates in conditional branches
 * - Variable shadowing in nested conditionals
 * - Boolean expression optimization
 * - Guard clause generation for pattern matching
 */
@:nullSafety(Off)
class ConditionalCompiler {
    
    /** Reference to main compiler for expression compilation */
    var compiler: ElixirCompiler;
    
    /**
     * Constructor
     * @param compiler Main ElixirCompiler instance for delegation
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
        
        #if debug_conditional_compilation
//         trace("[ConditionalCompiler] Initialized");
        #end
    }
    
    /**
     * Compiles if/else expressions to Elixir
     * 
     * WHY: If expressions in Haxe map to if-do-else-end in Elixir
     * WHAT: Transforms Haxe if expressions to idiomatic Elixir conditionals
     * HOW: Handles scoping and generates proper Elixir syntax
     * 
     * CRITICAL FIX: Detects array mutations in if branches and transforms them
     * to return values for reassignment, fixing the issue where array.push()
     * in if expressions doesn't update the outer array due to Elixir's immutability.
     * 
     * @param econd Condition expression to evaluate
     * @param eif Expression to execute if condition is true
     * @param eelse Optional expression to execute if condition is false
     * @return Generated Elixir if-do-else-end code
     */
    public function compileIfExpression(econd: TypedExpr, eif: TypedExpr, eelse: Null<TypedExpr>): String {
        #if debug_conditional_compilation
//         trace("[ConditionalCompiler] Compiling if expression");
//         trace('[ConditionalCompiler] Condition: ${econd.expr}');
//         trace('[ConditionalCompiler] Has else: ${eelse != null}');
        #end
        
        // CRITICAL: Check for array mutations that need special handling
        var arrayMutation = detectArrayMutation(eif);
        if (arrayMutation != null) {
            #if debug_conditional_compilation
//             trace("[ConditionalCompiler] Detected array mutation in if branch");
//             trace('[ConditionalCompiler] Array variable: ${arrayMutation.variable}');
            #end
            
            // Compile the condition
            var condStr = compiler.compileExpression(econd);
            
            // Extract just the mutation expression (e.g., "arr ++ [item]")
            var mutationExpr = extractMutationExpression(eif);
            
            // Handle else branch - if mutation in else, extract it too
            var elseMutation = if (eelse != null) detectArrayMutation(eelse) else null;
            var elseStr = if (elseMutation != null) {
                extractMutationExpression(eelse);
            } else if (eelse != null) {
                compiler.compileExpression(eelse);
            } else {
                arrayMutation.variable; // Return unchanged array
            };
            
            // Transform to: array = if cond, do: mutation, else: array_or_else_mutation
            return '${arrayMutation.variable} = if ${condStr}, do: ${mutationExpr}, else: ${elseStr}';
        }
        
        // Standard compilation for non-mutation cases
        var condStr = compiler.compileExpression(econd);
        var ifStr = compiler.compileExpression(eif);
        var elseStr = if (eelse != null) {
            compiler.compileExpression(eelse);
        } else {
            "nil";
        };
        
        // Generate Elixir conditional
        if (isSimpleExpression(eif) && (eelse == null || isSimpleExpression(eelse))) {
            // Use inline if for simple expressions
            return 'if ${condStr}, do: ${ifStr}, else: ${elseStr}';
        } else {
            // Use block if for complex expressions
            var result = 'if ${condStr} do\n';
            result += indent(ifStr) + '\n';
            result += 'else\n';
            result += indent(elseStr) + '\n';
            result += 'end';
            return result;
        }
    }
    
    /**
     * Compiles ternary expressions
     * 
     * WHY: Ternary operators need special handling for readability
     * WHAT: Transforms condition ? true_val : false_val to Elixir
     * HOW: Uses inline if or case expression based on complexity
     * 
     * @param econd Condition to evaluate
     * @param eif Value if true
     * @param eelse Value if false
     * @return Generated Elixir ternary expression
     */
    public function compileTernaryExpression(econd: TypedExpr, eif: TypedExpr, eelse: TypedExpr): String {
        #if debug_conditional_compilation
//         trace("[ConditionalCompiler] Compiling ternary expression");
        #end
        
        var condStr = compiler.compileExpression(econd);
        var ifStr = compiler.compileExpression(eif);
        var elseStr = compiler.compileExpression(eelse);
        
        // Always use inline if for ternary to maintain expression nature
        return 'if ${condStr}, do: ${ifStr}, else: ${elseStr}';
    }
    
    /**
     * Compiles guard clauses for pattern matching
     * 
     * WHY: Guard clauses in Elixir require special syntax
     * WHAT: Transforms Haxe conditions to Elixir when clauses
     * HOW: Generates proper guard syntax with operator restrictions
     * 
     * @param condition Guard condition expression
     * @return Generated Elixir guard clause
     */
    public function compileGuardClause(condition: TypedExpr): String {
        #if debug_conditional_compilation
//         trace("[ConditionalCompiler] Compiling guard clause");
        #end
        
        // Guard clauses have restricted expressions in Elixir
        return compileGuardExpression(condition);
    }
    
    /**
     * Checks if expression is simple enough for inline if
     * 
     * WHY: Complex expressions need block syntax for readability
     * WHAT: Determines if expression can be inlined
     * HOW: Checks expression complexity and structure
     * 
     * @param expr Expression to check
     * @return True if expression is simple
     */
    function isSimpleExpression(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TConst(_): true;
            case TLocal(_): true;
            case TField(_, _): true;
            case TCall(_, args) if (args.length <= 2): true;
            case TBinop(_, _, _): true;
            case TUnop(_, _, _): true;
            default: false;
        }
    }
    
    /**
     * Compiles guard-safe expressions
     * 
     * WHY: Elixir guards have restricted expression types
     * WHAT: Ensures expression is valid in guard context
     * HOW: Validates and transforms expression for guards
     * 
     * @param expr Expression to compile for guard
     * @return Guard-safe Elixir expression
     */
    function compileGuardExpression(expr: TypedExpr): String {
        return switch(expr.expr) {
            case TBinop(op, e1, e2):
                var left = compileGuardExpression(e1);
                var right = compileGuardExpression(e2);
                // Generate operator string directly for guards
                var opStr = switch(op) {
                    case OpAdd: "+";
                    case OpSub: "-";
                    case OpMult: "*";
                    case OpDiv: "/";
                    case OpMod: "rem";
                    case OpEq: "==";
                    case OpNotEq: "!=";
                    case OpLt: "<";
                    case OpLte: "<=";
                    case OpGt: ">";
                    case OpGte: ">=";
                    case OpBoolAnd: "and";
                    case OpBoolOr: "or";
                    default: "==";
                }
                '${left} ${opStr} ${right}';
                
            case TUnop(op, postFix, e):
                var exprStr = compileGuardExpression(e);
                // Generate unary operator string directly for guards
                var opStr = switch(op) {
                    case OpNot: "not ";
                    case OpNeg: "-";
                    case OpIncrement: "+1";  // Guards don't support ++
                    case OpDecrement: "-1";  // Guards don't support --
                    default: "";
                }
                if (postFix && (op == OpIncrement || op == OpDecrement)) {
                    '(${exprStr} ${opStr})';  // Simulate postfix with expression
                } else {
                    '${opStr}${exprStr}';
                }
                
            case TConst(c):
                compiler.expressionDispatcher.literalCompiler.compileConstant(c);
                
            case TLocal(v):
                compiler.variableCompiler.compileLocalVariable(v);
                
            case TField(e, fa):
                compiler.compileExpression(expr);
                
            default:
                // Fall back to regular expression compilation
                compiler.compileExpression(expr);
        }
    }
    
    /**
     * Adds indentation to code block
     * 
     * WHY: Proper indentation is crucial for readable Elixir code
     * WHAT: Adds consistent indentation to code blocks
     * HOW: Prepends spaces to each line
     * 
     * @param code Code to indent
     * @param level Indentation level (default 2 spaces)
     * @return Indented code
     */
    function indent(code: String, level: Int = 2): String {
        var spaces = [for (i in 0...level) " "].join("");
        return code.split("\n").map(line -> spaces + line).join("\n");
    }
    
    /**
     * Detects array mutation operations in an expression
     * 
     * WHY: Array mutations in if expressions need special handling in Elixir
     * WHAT: Identifies push(), concat(), or ++ operations on arrays
     * HOW: Pattern matches AST for specific mutation patterns
     * 
     * @param expr Expression to check for array mutations
     * @return Mutation info if detected, null otherwise
     */
    function detectArrayMutation(expr: TypedExpr): Null<ArrayMutationInfo> {
        if (expr == null) return null;
        
        #if debug_conditional_compilation
//         trace("[ConditionalCompiler] Checking for array mutation in expr: " + expr.expr);
        #end
        
        return switch(expr.expr) {
            // Direct call: array.push(item)
            case TCall({expr: TField(arrayExpr, FInstance(_, _, cf))}, args) 
                if (cf.get().name == "push" || cf.get().name == "concat"):
                {
                    variable: extractArrayVariableName(arrayExpr),
                    type: cf.get().name,
                    arrayExpr: arrayExpr,
                    args: args
                };
            
            // Binary operation: array = array ++ [item]
            case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, arr1, arr2)}):
                // Check if this is an array concatenation
                if (isArrayExpression(arr1)) {
                    {
                        variable: extractArrayVariableName(arr1),
                        type: "concat",
                        arrayExpr: arr1,
                        args: [arr2]
                    };
                } else {
                    null;
                }
                
            // Binary operation without assignment: array ++ [item]
            case TBinop(OpAdd, arr1, arr2):
                // Check if this is an array concatenation
                if (isArrayExpression(arr1)) {
                    {
                        variable: extractArrayVariableName(arr1),
                        type: "concat",
                        arrayExpr: arr1,
                        args: [arr2]
                    };
                } else {
                    null;
                }
                
            // Check nested blocks
            case TBlock(exprs) if (exprs.length > 0):
                // Check last expression in block
                detectArrayMutation(exprs[exprs.length - 1]);
                
            default:
                null;
        }
    }
    
    /**
     * Extracts the array variable name from an expression
     * 
     * WHY: Need to identify which array is being mutated
     * WHAT: Gets the variable name from various expression types
     * HOW: Pattern matches common array reference patterns
     * 
     * @param expr Array expression
     * @return Variable name as string
     */
    function extractArrayVariableName(expr: TypedExpr): String {
        return switch(expr.expr) {
            case TLocal(v):
                compiler.variableCompiler.compileLocalVariable(v);
            case TField(e, _):
                compiler.compileExpression(expr);
            default:
                compiler.compileExpression(expr);
        }
    }
    
    /**
     * Checks if an expression represents an array
     * 
     * WHY: Need to distinguish array operations from other operations
     * WHAT: Determines if expression is array-typed
     * HOW: Checks type information
     * 
     * @param expr Expression to check
     * @return True if array expression
     */
    function isArrayExpression(expr: TypedExpr): Bool {
        return switch(expr.t) {
            case TInst(_.get() => {name: "Array"}, _): true;
            default: 
                // Also check for local variables that might be arrays
                switch(expr.expr) {
                    case TLocal(_): true; // Assume locals could be arrays
                    default: false;
                }
        }
    }
    
    /**
     * Extracts just the mutation expression without assignment
     * 
     * WHY: Need the pure mutation expression for the transformed if
     * WHAT: Gets "arr ++ [item]" from "arr = arr ++ [item]"
     * HOW: Compiles the mutation part of the expression
     * 
     * @param expr Expression containing mutation
     * @return Mutation expression string
     */
    function extractMutationExpression(expr: TypedExpr): String {
        var mutation = detectArrayMutation(expr);
        if (mutation == null) {
            return compiler.compileExpression(expr);
        }
        
        // Compile based on mutation type
        return switch(mutation.type) {
            case "push":
                var arrayStr = extractArrayVariableName(mutation.arrayExpr);
                var argStr = if (mutation.args.length > 0) {
                    compiler.compileExpression(mutation.args[0]);
                } else {
                    "nil";
                };
                '${arrayStr} ++ [${argStr}]';
                
            case "concat":
                var arrayStr = extractArrayVariableName(mutation.arrayExpr);
                var argStr = if (mutation.args.length > 0) {
                    compiler.compileExpression(mutation.args[0]);
                } else {
                    "[]";
                };
                '${arrayStr} ++ ${argStr}';
                
            default:
                compiler.compileExpression(expr);
        }
    }
}

/**
 * Information about detected array mutation
 */
private typedef ArrayMutationInfo = {
    variable: String,
    type: String,
    arrayExpr: TypedExpr,
    args: Array<TypedExpr>
}

#end