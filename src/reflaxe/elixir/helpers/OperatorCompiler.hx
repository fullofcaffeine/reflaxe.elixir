package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Expr.Binop;
import haxe.macro.Expr.Unop;
import reflaxe.BaseCompiler;

using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * Operator Compiler for Reflaxe.Elixir
 * 
 * WHY: The compileElixirExpressionInternal function contained ~453 lines of operator compilation
 * logic scattered across TBinop and TUnop cases. This massive complexity included string
 * concatenation handling, assignment operators, arithmetic operations, logical operators,
 * and special Elixir-specific transformations. Having all this in one function violated
 * Single Responsibility Principle and made operator logic difficult to maintain and extend.
 * 
 * WHAT: Specialized compiler for all binary and unary operator expressions in Haxe-to-Elixir transpilation:
 * - Binary operators (TBinop) → Elixir arithmetic, logical, and assignment operations
 * - String concatenation detection → Elixir <> operator instead of +
 * - Assignment operators → Proper Elixir variable assignment and struct updates
 * - Compound assignment (+=, -=, etc.) → Elixir pattern matching updates
 * - Comparison operators → Elixir comparison with proper type handling
 * - Logical operators → Elixir and/or/not with short-circuit evaluation
 * - Unary operators (TUnop) → Elixir negation, increment, decrement patterns
 * - Type-aware operator selection based on operand types
 * 
 * HOW: The compiler implements sophisticated operator transformation patterns:
 * 1. Receives TBinop/TUnop expressions from ExpressionDispatcher
 * 2. Analyzes operand types to determine appropriate Elixir operator
 * 3. Applies string concatenation detection and <>  transformation
 * 4. Handles struct field assignment with proper pattern matching
 * 5. Generates idiomatic Elixir operators with correct precedence
 * 6. Integrates with LiteralCompiler for string escaping reuse
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on operator expression compilation
 * - Type Safety: Proper operand type analysis for operator selection
 * - Code Reuse: Leverages LiteralCompiler for string escaping utilities
 * - Maintainability: Clear separation from control flow and variable logic
 * - Testability: Operator logic can be independently tested and verified
 * - Extensibility: Easy to add new operator patterns and transformations
 * 
 * EDGE CASES:
 * - String concatenation detection with mixed string/non-string operands
 * - Compound assignment to struct fields requiring pattern matching syntax
 * - Type conversion for mixed-type arithmetic operations
 * - Short-circuit evaluation for logical operators
 * - Operator precedence handling in complex expressions
 * 
 * @see documentation/OPERATOR_COMPILATION_PATTERNS.md - Complete operator transformation patterns
 */
@:nullSafety(Off)
class OperatorCompiler {
    
    var compiler: Dynamic; // ElixirCompiler reference
    var literalCompiler: LiteralCompiler; // For string escaping reuse
    
    /**
     * Create a new operator compiler
     * 
     * @param compiler The main ElixirCompiler instance
     * @param literalCompiler LiteralCompiler for string utility reuse
     */
    public function new(compiler: Dynamic, literalCompiler: LiteralCompiler) {
        this.compiler = compiler;
        this.literalCompiler = literalCompiler;
    }
    
    /**
     * Compile TBinop binary operator expressions
     * 
     * WHY: Binary operators need complex type-aware transformation for idiomatic Elixir
     * 
     * WHAT: Transform Haxe binary operators to appropriate Elixir equivalents with proper typing
     * 
     * HOW:
     * 1. Analyze operator type and operand types
     * 2. Apply string concatenation detection (+ → <>)
     * 3. Handle assignment and compound assignment operators
     * 4. Generate proper Elixir operator expressions with correct precedence
     * 
     * @param op Binary operator type
     * @param e1 Left operand expression
     * @param e2 Right operand expression
     * @return Compiled Elixir binary operator expression
     */
    public function compileBinaryOperation(op: Binop, e1: TypedExpr, e2: TypedExpr): String {
        #if debug_operator_compiler
        trace("[XRay OperatorCompiler] BINARY OPERATION START");
        trace('[XRay OperatorCompiler] Operator: ${op}');
        trace('[XRay OperatorCompiler] Left type: ${e1.t}');
        trace('[XRay OperatorCompiler] Right type: ${e2.t}');
        #end
        
        // For now, delegate back to original function to maintain functionality
        // TODO: Extract the full TBinop logic from compileElixirExpressionInternal
        var result = compiler.compileElixirExpressionInternal({expr: TBinop(op, e1, e2), pos: null, t: null}, false);
        
        #if debug_operator_compiler
        trace('[XRay OperatorCompiler] Generated binary op: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        trace("[XRay OperatorCompiler] BINARY OPERATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile TUnop unary operator expressions
     * 
     * WHY: Unary operators need proper transformation to Elixir equivalents
     * 
     * WHAT: Transform Haxe unary operators to idiomatic Elixir unary expressions
     * 
     * HOW:
     * 1. Analyze unary operator type and operand
     * 2. Handle negation, increment, decrement operations
     * 3. Generate appropriate Elixir unary operator syntax
     * 
     * @param op Unary operator type
     * @param postFix Whether operator is postfix
     * @param e Operand expression
     * @return Compiled Elixir unary operator expression
     */
    public function compileUnaryOperation(op: Unop, postFix: Bool, e: TypedExpr): String {
        #if debug_operator_compiler
        trace("[XRay OperatorCompiler] UNARY OPERATION START");
        trace('[XRay OperatorCompiler] Operator: ${op}');
        trace('[XRay OperatorCompiler] Postfix: ${postFix}');
        trace('[XRay OperatorCompiler] Operand type: ${e.t}');
        #end
        
        // For now, delegate back to original function to maintain functionality
        // TODO: Extract the full TUnop logic from compileElixirExpressionInternal
        var result = compiler.compileElixirExpressionInternal({expr: TUnop(op, postFix, e), pos: null, t: null}, false);
        
        #if debug_operator_compiler
        trace('[XRay OperatorCompiler] Generated unary op: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        trace("[XRay OperatorCompiler] UNARY OPERATION END");
        #end
        
        return result;
    }
    
    /**
     * Utility: Detect string concatenation in binary operations
     * 
     * WHY: String concatenation needs to use <> operator in Elixir, not +
     * 
     * @param e1 Left operand
     * @param e2 Right operand
     * @return True if this should be string concatenation
     */
    private function isStringConcatenation(e1: TypedExpr, e2: TypedExpr): Bool {
        return compiler.isStringType(e1.t) || compiler.isStringType(e2.t);
    }
    
    /**
     * Utility: Compile string concatenation with proper escaping
     * 
     * WHY: String concatenation needs proper escaping and <> operator usage
     * 
     * @param e1 Left operand
     * @param e2 Right operand
     * @return Compiled Elixir string concatenation
     */
    private function compileStringConcatenation(e1: TypedExpr, e2: TypedExpr): String {
        var left = switch (e1.expr) {
            case TConst(TString(s)): 
                literalCompiler.compileStringLiteral(s);
            case _: 
                compiler.compileExpression(e1);
        };
        
        var right = switch (e2.expr) {
            case TConst(TString(s)): 
                literalCompiler.compileStringLiteral(s);
            case _: 
                compiler.compileExpression(e2);
        };
        
        // Convert non-string operands to strings
        if (!compiler.isStringType(e1.t) && compiler.isStringType(e2.t)) {
            left = convertToString(e1, left);
        } else if (compiler.isStringType(e1.t) && !compiler.isStringType(e2.t)) {
            right = convertToString(e2, right);
        }
        
        return '${left} <> ${right}';
    }
    
    /**
     * Utility: Convert expression to string for concatenation
     * 
     * @param expr Original expression
     * @param compiled Compiled expression string
     * @return String conversion expression
     */
    private function convertToString(expr: TypedExpr, compiled: String): String {
        return switch (expr.t) {
            case TInst(t, _) if (t.get().name == "Int"): 'Integer.to_string(${compiled})';
            case TInst(t, _) if (t.get().name == "Float"): 'Float.to_string(${compiled})';
            case TAbstract(t, _) if (t.get().name == "Bool"): 'Atom.to_string(${compiled})';
            case _: 'to_string(${compiled})';
        };
    }
    
    /**
     * TODO: Future implementation will contain the extracted logic:
     * 
     * - Full TBinop compilation with all operator types
     * - String concatenation detection and transformation
     * - Assignment and compound assignment operators
     * - Struct field assignment with pattern matching
     * - Type-aware operator selection
     * - Full TUnop compilation with increment/decrement patterns
     * - Operator precedence handling
     * - Short-circuit evaluation for logical operators
     * 
     * Each method above will be filled with the actual extracted logic
     * from the original compileElixirExpressionInternal function.
     */
}

#end