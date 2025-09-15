package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * BinaryOpBuilder: Binary Operation Construction for ElixirAST
 *
 * WHY: Binary operations need specialized handling for type-aware operator selection,
 * compound assignments, and Elixir-specific operators. String concatenation vs addition,
 * null coalescing, and immutable compound assignments require careful handling.
 *
 * WHAT: Handles TypedExpr cases for:
 * - Arithmetic operations (+, -, *, /, %)
 * - Comparison operations (==, !=, <, <=, >, >=)
 * - Logical operations (&&, ||)
 * - Bitwise operations (&, |, ^, <<, >>)
 * - String concatenation (automatic detection)
 * - Compound assignments (+=, -=, etc.)
 * - Special operators (??, .., ...)
 *
 * HOW: Provides static functions that generate appropriate ElixirAST nodes
 * based on operator type and operand types. Detects string operations
 * through type inspection.
 *
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles binary operations
 * - Type awareness: String vs numeric operations
 * - Idiomatic output: Generates proper Elixir operators
 * - Testability: Binary operation logic isolated
 *
 * EDGE CASES:
 * - String concatenation uses <> not +
 * - Compound assignments need rebinding
 * - Null coalescing needs temp variables
 * - Unsigned shift doesn't exist in Elixir
 */
class BinaryOpBuilder {

    /**
     * Build binary operation expression
     *
     * WHY: Binary operations need type-aware handling
     * WHAT: Converts TBinop to appropriate ElixirAST
     * HOW: Checks operator and operand types to select correct operation
     */
    public static function buildBinop(op: Binop, e1: TypedExpr, e2: TypedExpr,
                                     buildExpr: TypedExpr -> ElixirAST,
                                     extractPattern: TypedExpr -> EPattern,
                                     toSnakeCase: String -> String,
                                     metadata: ElixirMetadata = null): ElixirAST {

        // Special handling for field != nil or field == nil comparisons
        var isNilComparison = switch(op) {
            case OpEq | OpNotEq:
                switch(e2.expr) {
                    case TConst(TNull): true;
                    default: false;
                }
            default: false;
        };

        // Build left operand with special handling for optional field access
        var left = switch(e1.expr) {
            case TField(target, FAnon(cf)) if (isNilComparison):
                // For optional field checks, use Map.get for safe access
                var targetAst = buildExpr(target);
                var fieldName = toSnakeCase(cf.get().name);
                makeAST(ERemoteCall(
                    makeAST(EVar("Map")),
                    "get",
                    [targetAst, makeAST(EAtom(fieldName))]
                ));
            case _:
                buildExpr(e1);
        };

        var right = buildExpr(e2);

        var def = switch(op) {
            case OpAdd:
                // Detect string concatenation based on left operand type
                var isStringConcat = isStringType(e1.t);

                if (isStringConcat) {
                    // For string concatenation, ensure right operand is a string
                    var rightStr = if (isStringType(e2.t)) {
                        right;
                    } else {
                        // Non-string needs conversion
                        makeAST(ERemoteCall(makeAST(EVar("Kernel")), "to_string", [right]));
                    };
                    EBinary(StringConcat, left, rightStr);
                } else {
                    EBinary(Add, left, right);
                }

            case OpSub: EBinary(Subtract, left, right);
            case OpMult: EBinary(Multiply, left, right);
            case OpDiv: EBinary(Divide, left, right);
            case OpMod: EBinary(Remainder, left, right);

            case OpEq: EBinary(Equal, left, right);
            case OpNotEq: EBinary(NotEqual, left, right);
            case OpLt: EBinary(Less, left, right);
            case OpLte: EBinary(LessEqual, left, right);
            case OpGt: EBinary(Greater, left, right);
            case OpGte: EBinary(GreaterEqual, left, right);

            case OpBoolAnd: EBinary(AndAlso, left, right);
            case OpBoolOr: EBinary(OrElse, left, right);

            case OpAssign: EMatch(extractPattern(e1), right);

            case OpAssignOp(op2):
                // Transform compound assignment: a += b becomes a = a + b
                var innerOp = if (op2 == OpAdd) {
                    // Detect string concatenation
                    isStringType(e1.t) ? StringConcat : Add;
                } else {
                    convertAssignOp(op2);
                };
                EMatch(extractPattern(e1), makeAST(EBinary(innerOp, left, right)));

            case OpAnd: EBinary(BitwiseAnd, left, right);
            case OpOr: EBinary(BitwiseOr, left, right);
            case OpXor: EBinary(BitwiseXor, left, right);
            case OpShl: EBinary(ShiftLeft, left, right);
            case OpShr: EBinary(ShiftRight, left, right);
            case OpUShr: EBinary(ShiftRight, left, right); // No unsigned in Elixir

            case OpInterval:
                // Haxe's ... is exclusive, convert to inclusive with end-1
                ERange(left, makeAST(EBinary(Subtract, right, makeAST(EInteger(1)))), false);

            case OpArrow:
                EFn([{
                    args: [PVar("_arrow")], // Placeholder, will be transformed
                    body: right
                }]);

            case OpIn: EBinary(In, left, right);

            case OpNullCoal:
                // a ?? b needs special handling to avoid double evaluation
                buildNullCoalescing(left, right);
        };

        return metadata != null ? makeASTWithMeta(def, metadata) : makeAST(def);
    }

    /**
     * Check if a type is a String type
     *
     * WHY: String operations need different operators than numeric
     * WHAT: Detects String class or abstract type
     * HOW: Pattern matches on Type structure
     */
    static function isStringType(t: Type): Bool {
        return switch(t) {
            case TInst(_.get() => {name: "String"}, _): true;
            case TAbstract(_.get() => {name: "String"}, _): true;
            default: false;
        };
    }

    /**
     * Convert compound assignment operator to binary operator
     *
     * WHY: Compound assignments expand to binary operations
     * WHAT: Maps OpAssignOp inner operator to EBinaryOp
     * HOW: Direct mapping of operator types
     */
    static function convertAssignOp(op: Binop): EBinaryOp {
        return switch(op) {
            case OpAdd: Add;
            case OpSub: Subtract;
            case OpMult: Multiply;
            case OpDiv: Divide;
            case OpMod: Remainder;
            case OpAnd: BitwiseAnd;
            case OpOr: BitwiseOr;
            case OpXor: BitwiseXor;
            case OpShl: ShiftLeft;
            case OpShr: ShiftRight;
            case OpUShr: ShiftRight;
            default: throw 'Unsupported assign op: $op';
        };
    }

    /**
     * Build null coalescing expression
     *
     * WHY: a ?? b needs to avoid double evaluation of a
     * WHAT: Generates if expression with temp variable for complex expressions
     * HOW: Checks if expression is simple enough to reference multiple times
     */
    static function buildNullCoalescing(left: ElixirAST, right: ElixirAST): ElixirASTDef {
        // Check if left is simple enough to reference multiple times
        var isSimple = switch(left.def) {
            case EVar(_): true;
            case ENil: true;
            case EBoolean(_): true;
            case EInteger(_): true;
            case EString(_): true;
            case _: false;
        };

        if (isSimple) {
            // Simple expression can be used directly
            var ifExpr = makeAST(EIf(
                makeAST(EBinary(NotEqual, left, makeAST(ENil))),
                left,
                right
            ));
            // Mark as inline for null coalescing
            if (ifExpr.metadata == null) ifExpr.metadata = {};
            ifExpr.metadata.keepInlineInAssignment = true;
            return ifExpr.def;
        } else {
            // Complex expression needs temp variable
            var tmpVar = makeAST(EVar("tmp"));
            var assignment = makeAST(EMatch(PVar("tmp"), left));

            var ifExpr = makeAST(EIf(
                makeAST(EBinary(NotEqual, assignment, makeAST(ENil))),
                tmpVar,
                right
            ));
            // Set metadata to indicate this should stay inline
            if (ifExpr.metadata == null) ifExpr.metadata = {};
            ifExpr.metadata.keepInlineInAssignment = true;
            return ifExpr.def;
        }
    }
}

#end