package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.EBinaryOp;
import reflaxe.elixir.ast.ElixirAST.EUnaryOp;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * CoreExprBuilder: Basic Expression Construction for ElixirAST
 *
 * WHY: Isolate basic expression building (literals, variables, simple operations)
 * from the monolithic ElixirASTBuilder to improve maintainability and testability.
 * Basic expressions are the foundation of all other AST constructs.
 *
 * WHAT: Handles TypedExpr cases for:
 * - Constants (strings, integers, floats, booleans, null)
 * - Local variables and this references
 * - Binary operations with proper operator mapping
 * - Simple unary operations
 *
 * HOW: Provides static functions that convert TypedExpr nodes to ElixirAST nodes
 * with proper metadata preservation. Uses callback pattern to avoid circular
 * dependencies with the main builder.
 *
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles basic expressions
 * - Zero coupling: No dependencies on other builders
 * - Pure functions: All methods are stateless transformations
 * - Testability: Can unit test literal and variable generation
 *
 * EDGE CASES:
 * - Null values compile to 'nil' atom
 * - Boolean true/false become atoms
 * - String escaping handled by printer phase
 */
class CoreExprBuilder {

    /**
     * Build constant literal expressions
     *
     * WHY: Constants are the simplest AST nodes and most common
     * WHAT: Converts TConst to appropriate Elixir literal
     * HOW: Pattern matches on constant type and creates corresponding AST
     */
    public static function buildConst(c: TConstant, metadata: ElixirMetadata = null): ElixirAST {
        var def = switch(c) {
            case TInt(i):
                ElixirASTDef.EInteger(i);
            case TFloat(f):
                ElixirASTDef.EFloat(Std.parseFloat(f));
            case TString(s):
                ElixirASTDef.EString(s);
            case TBool(b):
                ElixirASTDef.EBoolean(b);
            case TNull:
                ElixirASTDef.ENil;
            case TThis:
                ElixirASTDef.EVar("self");
            case TSuper:
                ElixirASTDef.EVar("super"); // Will be transformed later
        };

        return metadata != null ? makeASTWithMeta(def, metadata) : makeAST(def);
    }

    /**
     * Build local variable references
     *
     * WHY: Variables are fundamental to all expressions
     * WHAT: Creates EVar node with proper naming
     * HOW: Converts variable name to snake_case using ElixirNaming
     */
    public static function buildLocal(v: TVar, metadata: ElixirMetadata = null): ElixirAST {
        if (metadata == null) metadata = {};

        // Store the original variable ID for later resolution
        metadata.sourceVarId = v.id;

        // Convert variable name to Elixir snake_case convention
        var elixirVarName = reflaxe.elixir.ast.naming.ElixirNaming.toVarName(v.name);

        return makeASTWithMeta(ElixirASTDef.EVar(elixirVarName), metadata);
    }

    /**
     * Build binary operator nodes
     *
     * WHY: Binary operations need consistent operator mapping
     * WHAT: Converts Haxe Binop to Elixir EBinaryOp
     * HOW: Direct mapping of operator types
     */
    public static function buildBinop(op: Binop): EBinaryOp {
        return switch(op) {
            // Arithmetic
            case OpAdd: EBinaryOp.Add;
            case OpMult: EBinaryOp.Multiply;
            case OpDiv: EBinaryOp.Divide;
            case OpSub: EBinaryOp.Subtract;
            case OpMod: EBinaryOp.Remainder;

            // Assignment (handled separately in builder)
            case OpAssign: throw "Assignment should be handled as EMatch";
            case OpAssignOp(_): throw "Compound assignment needs special handling";

            // Comparison
            case OpEq: EBinaryOp.Equal;
            case OpNotEq: EBinaryOp.NotEqual;
            case OpGt: EBinaryOp.Greater;
            case OpGte: EBinaryOp.GreaterEqual;
            case OpLt: EBinaryOp.Less;
            case OpLte: EBinaryOp.LessEqual;

            // Logical
            case OpBoolAnd: EBinaryOp.And;
            case OpBoolOr: EBinaryOp.Or;

            // Bitwise
            case OpAnd: EBinaryOp.BitwiseAnd;
            case OpOr: EBinaryOp.BitwiseOr;
            case OpXor: EBinaryOp.BitwiseXor;
            case OpShl: EBinaryOp.ShiftLeft;
            case OpShr: EBinaryOp.ShiftRight;
            case OpUShr: EBinaryOp.ShiftRight; // Elixir doesn't have unsigned shift

            // Special
            case OpInterval: throw "Interval operator needs special handling";
            case OpArrow: throw "Arrow operator needs special handling";
            case OpIn: EBinaryOp.In;
            case OpNullCoal: throw "Null coalescing needs special handling";
        };
    }

    /**
     * Build unary operator expressions
     *
     * WHY: Unary operations need proper prefix/postfix handling
     * WHAT: Creates appropriate unary operation AST
     * HOW: Maps to Elixir unary operators
     */
    public static function buildUnop(op: Unop, postfix: Bool, e: ElixirAST, metadata: ElixirMetadata = null): ElixirAST {
        if (metadata == null) metadata = {};

        var def = switch(op) {
            case OpIncrement:
                // x++ becomes x = x + 1
                // Note: requiresRebinding would need to be handled by transformer
                ElixirASTDef.EBinary(EBinaryOp.Add, e, makeAST(ElixirASTDef.EInteger(1)));

            case OpDecrement:
                // x-- becomes x = x - 1
                // Note: requiresRebinding would need to be handled by transformer
                ElixirASTDef.EBinary(EBinaryOp.Subtract, e, makeAST(ElixirASTDef.EInteger(1)));

            case OpNot:
                // !x becomes not x
                ElixirASTDef.EUnary(EUnaryOp.Not, e);

            case OpNeg:
                // -x becomes -x
                ElixirASTDef.EUnary(EUnaryOp.Negate, e);

            case OpNegBits:
                // ~x becomes ~~~x (Bitwise NOT in Elixir)
                EUnary(BitwiseNot, e);

            case OpSpread:
                // ...x handled in context (array spread, etc.)
                throw "Spread operator requires context";
        };

        return makeASTWithMeta(def, metadata);
    }
}

#end