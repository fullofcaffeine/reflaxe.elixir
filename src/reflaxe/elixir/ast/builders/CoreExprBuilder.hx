package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
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
                EInteger(i);
            case TFloat(f):
                EFloat(Std.parseFloat(f));
            case TString(s):
                EString(s);
            case TBool(b):
                EBoolean(b);
            case TNull:
                ENil;
            case TThis:
                EVar("self");
            case TSuper:
                EVar("super"); // Will be transformed later
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

        return makeASTWithMeta(EVar(elixirVarName), metadata);
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
            case OpAdd: Add;
            case OpMult: Multiply;
            case OpDiv: Divide;
            case OpSub: Subtract;
            case OpMod: Remainder;

            // Assignment (handled separately in builder)
            case OpAssign: throw "Assignment should be handled as EMatch";
            case OpAssignOp(_): throw "Compound assignment needs special handling";

            // Comparison
            case OpEq: Equal;
            case OpNotEq: NotEqual;
            case OpGt: Greater;
            case OpGte: GreaterEqual;
            case OpLt: Less;
            case OpLte: LessEqual;

            // Logical
            case OpBoolAnd: And;
            case OpBoolOr: Or;

            // Bitwise
            case OpAnd: BitwiseAnd;
            case OpOr: BitwiseOr;
            case OpXor: BitwiseXor;
            case OpShl: ShiftLeft;
            case OpShr: ShiftRight;
            case OpUShr: ShiftRight; // Elixir doesn't have unsigned shift

            // Special
            case OpInterval: throw "Interval operator needs special handling";
            case OpArrow: throw "Arrow operator needs special handling";
            case OpIn: In;
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
                EBinary(Add, e, makeAST(EInteger(1)));

            case OpDecrement:
                // x-- becomes x = x - 1
                // Note: requiresRebinding would need to be handled by transformer
                EBinary(Subtract, e, makeAST(EInteger(1)));

            case OpNot:
                // !x becomes not x
                EUnary(Not, e);

            case OpNeg:
                // -x becomes -x
                EUnary(Negate, e);

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