package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.EBinaryOp;
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
     * Build binary operation from pre-built AST nodes
     *
     * WHY: Avoids infinite recursion by accepting already-built operands. When modularizing
     * recursive AST builders, the "driver" (ElixirASTBuilder) must own all recursion to prevent
     * infinite loops. Specialized builders receive pre-transformed children.
     *
     * WHAT: Creates binary operation AST from pre-built left and right operands that have
     * already been transformed from TypedExpr to ElixirAST by the main builder.
     *
     * HOW: Combines pre-built ASTs with the appropriate Elixir operator based on the
     * binary operation type and operand types (e.g., string concatenation vs addition).
     *
     * @param op The binary operator (OpAdd, OpEq, OpAssign, etc.) from Haxe's AST
     * @param leftAST The pre-built ElixirAST for the left operand (e.g., a variable, literal, or expression)
     *                Example: For "x + 1", leftAST would be EVar("x") already built from TLocal
     * @param rightAST The pre-built ElixirAST for the right operand
     *                 Example: For "x + 1", rightAST would be EInteger(1) already built from TConst
     * @param e1 The original TypedExpr for the left operand (kept for type checking)
     *           Used to determine if we need string concatenation vs numeric addition
     * @param e2 The original TypedExpr for the right operand (kept for type checking)
     *           Used for type analysis without triggering recursion
     * @param toSnakeCase Function to convert camelCase to snake_case for Elixir naming
     * @param metadata Optional metadata to attach to the resulting AST node
     * @return ElixirAST node representing the binary operation
     *
     * ## Example Usage:
     * ```haxe
     * // In ElixirASTBuilder when processing "x + 1":
     * case TBinop(OpAdd, e1, e2):
     *     var leftAST = buildFromTypedExpr(e1, context);   // Builds EVar("x")
     *     var rightAST = buildFromTypedExpr(e2, context);  // Builds EInteger(1)
     *     return BinaryOpBuilder.buildBinopFromAST(
     *         OpAdd, leftAST, rightAST, e1, e2, toSnakeCase
     *     );  // Returns EBinary(Add, EVar("x"), EInteger(1))
     * ```
     *
     * ## Architecture Pattern:
     * This follows the "driver + handlers" pattern where:
     * - ElixirASTBuilder is the driver that controls recursion
     * - BinaryOpBuilder is a handler that receives pre-processed inputs
     * - No callbacks to buildExpr prevents re-entry and infinite loops
     */
    public static function buildBinopFromAST(op: Binop, leftAST: ElixirAST, rightAST: ElixirAST,
                                            e1: TypedExpr, e2: TypedExpr,  // Original exprs for type checking
                                            toSnakeCase: String -> String,
                                            metadata: ElixirMetadata = null): ElixirAST {

        var def = switch(op) {
            case OpAdd:
                // Detect string concatenation based on EITHER operand being a string
                // This handles cases like 1 + " × " where Haxe unrolls loops with concrete values
                var leftIsString = isStringType(e1.t);
                var rightIsString = isStringType(e2.t);
                var isStringConcat = leftIsString || rightIsString;

                if (isStringConcat) {
                    // For string concatenation, ensure both operands are strings.
                    // Use Kernel.to_string/1 for coercion to avoid instance method rewrites.
                    inline function toKernelString(e: ElixirAST): ElixirAST {
                        return makeAST(ElixirASTDef.ERemoteCall(makeAST(ElixirASTDef.EVar("Kernel")), "to_string", [e]));
                    }

                    var leftStr = leftIsString ? leftAST : toKernelString(leftAST);

                    var rightStr = if (rightIsString) {
                        rightAST;
                    } else {
                        // Avoid coercion on ERaw or complex block forms that already ensure binaries
                        var needsToString = switch(rightAST.def) {
                            case ERaw(_): false;
                            case ECase(_, _) | ECond(_) | EWith(_, _, _): false;
                            case EIf(_, _, elseBranch) if (elseBranch != null): false;
                            case EBlock(exprs) if (exprs.length > 0):
                                var lastExpr = exprs[exprs.length - 1];
                                switch(lastExpr.def) {
                                    case ECase(_, _) | ECond(_) | EWith(_, _, _): false;
                                    case EIf(_, _, elseBranch) if (elseBranch != null): false;
                                    default: true;
                                }
                            default: true;
                        };
                        needsToString ? toKernelString(rightAST) : rightAST;
                    };

                    // String concatenation in Elixir uses <> operator
                    ElixirASTDef.EBinary(EBinaryOp.StringConcat, leftStr, rightStr);
                } else {
                    // Regular addition with defensive identity fallback:
                    // If either side somehow became null during upstream transforms,
                    // substitute 0 to preserve valid syntax and additive identity.
                    var safeLeft  = (leftAST  != null) ? leftAST  : makeAST(EInteger(0));
                    var safeRight = rightAST;
                    if (safeRight == null) {
                        // Attempt to recover from original TypedExpr e2 for common literals/vars
                        safeRight = switch (e2.expr) {
                            case TConst(TInt(b)): makeAST(EInteger(b));
                            case TConst(TFloat(f)): makeAST(EFloat(Std.parseFloat(Std.string(f))));
                            case TLocal(v): makeAST(EVar(v.name));
                            default: makeAST(EInteger(0)); // identity fallback
                        };
                    }
                    ElixirASTDef.EBinary(EBinaryOp.Add, safeLeft, safeRight);
                }

            // Assignment and compound assignments
            case OpAssign:
                // Assignments require pattern extraction from the left operand,
                // which needs access to extractPattern() from ElixirASTBuilder.
                // This is handled in ElixirASTBuilder's TBinop case to avoid
                // circular dependencies and maintain clear architectural boundaries.
                // This case should not be reached - ElixirASTBuilder handles OpAssign specially.
                throw "OpAssign should be handled in ElixirASTBuilder";

            case OpAssignOp(innerOp):
                // Compound assignments (+=, -=, etc.) also require pattern extraction
                // and are handled in ElixirASTBuilder's TBinop case.
                // This case should not be reached - ElixirASTBuilder handles OpAssignOp specially.
                throw "OpAssignOp should be handled in ElixirASTBuilder";

            // Arithmetic operations
            case OpMult:
                ElixirASTDef.EBinary(EBinaryOp.Multiply, leftAST, rightAST);
            case OpDiv:
                ElixirASTDef.EBinary(EBinaryOp.Divide, leftAST, rightAST);
            case OpSub:
                ElixirASTDef.EBinary(EBinaryOp.Subtract, leftAST, rightAST);
            case OpMod:
                ElixirASTDef.EBinary(EBinaryOp.Remainder, leftAST, rightAST);

            // Comparison operations
            case OpEq:
                ElixirASTDef.EBinary(EBinaryOp.Equal, leftAST, rightAST);
            case OpNotEq:
                ElixirASTDef.EBinary(EBinaryOp.NotEqual, leftAST, rightAST);
            case OpGt:
                ElixirASTDef.EBinary(EBinaryOp.Greater, leftAST, rightAST);
            case OpGte:
                ElixirASTDef.EBinary(EBinaryOp.GreaterEqual, leftAST, rightAST);
            case OpLt:
                ElixirASTDef.EBinary(EBinaryOp.Less, leftAST, rightAST);
            case OpLte:
                ElixirASTDef.EBinary(EBinaryOp.LessEqual, leftAST, rightAST);

            // Logical operations
            case OpBoolAnd:
                ElixirASTDef.EBinary(EBinaryOp.And, leftAST, rightAST);
            case OpBoolOr:
                ElixirASTDef.EBinary(EBinaryOp.Or, leftAST, rightAST);

            // Bitwise operations
            case OpAnd:
                ElixirASTDef.EBinary(EBinaryOp.BitwiseAnd, leftAST, rightAST);
            case OpOr:
                ElixirASTDef.EBinary(EBinaryOp.BitwiseOr, leftAST, rightAST);
            case OpXor:
                ElixirASTDef.EBinary(EBinaryOp.BitwiseXor, leftAST, rightAST);
            case OpShl:
                ElixirASTDef.EBinary(EBinaryOp.ShiftLeft, leftAST, rightAST);
            case OpShr:
                ElixirASTDef.EBinary(EBinaryOp.ShiftRight, leftAST, rightAST);
            case OpUShr:
                ElixirASTDef.EBinary(EBinaryOp.ShiftRight, leftAST, rightAST); // No unsigned shift in Elixir

            // Special operations
            case OpInterval:
                ElixirASTDef.ERange(leftAST, rightAST, false);  // Inclusive range by default
            case OpIn:
                ElixirASTDef.EBinary(EBinaryOp.In, leftAST, rightAST);
            case OpNullCoal:
                // a ?? b becomes: if a == nil, do: b, else: a
                var nilCheck = makeAST(ElixirASTDef.EBinary(EBinaryOp.Equal, leftAST, makeAST(ElixirASTDef.ENil)));
                ElixirASTDef.EIf(nilCheck, rightAST, leftAST);
            case OpArrow:
                throw "Arrow operator not supported in Elixir context";
        };

        return metadata != null ? makeASTWithMeta(def, metadata) : makeAST(def);
    }

    /**
     * Build binary operation expression (DEPRECATED - causes infinite recursion)
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
