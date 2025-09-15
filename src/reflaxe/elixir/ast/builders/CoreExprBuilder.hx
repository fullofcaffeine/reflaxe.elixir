package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.CompilationContext;

/**
 * CoreExprBuilder: Builds ElixirAST nodes for basic expressions
 *
 * WHY: Extracts core expression building logic from the monolithic ElixirASTBuilder
 * to create a focused, testable module that handles basic expression types.
 *
 * WHAT: Converts basic TypedExpr nodes to ElixirAST:
 * - Constants (integers, strings, booleans, null)
 * - Variables (local references, parameters)
 * - Basic operators (arithmetic, comparison, logical)
 * - Field access and simple type references
 *
 * HOW: Provides static methods that take TypedExpr and CompilationContext,
 * returning ElixirAST nodes. Uses context for variable naming resolution
 * and state tracking without static contamination.
 *
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles basic expressions
 * - Testability: Can test core expression building in isolation
 * - Maintainability: Clear boundaries and focused logic
 * - Performance: Lightweight with minimal dependencies
 *
 * @see ElixirASTBuilder for integration point
 * @see CompilationContext for state management
 */
class CoreExprBuilder {

    /**
     * Build constant expressions
     *
     * WHY: Constants are the most basic building blocks of any expression
     * WHAT: Converts TConst nodes to appropriate ElixirAST equivalents
     * HOW: Maps each constant type to its Elixir representation
     */
    public static function buildConst(c: TConstant, context: CompilationContext): ElixirASTDef {
        return switch(c) {
            case TInt(i): EInteger(i);
            case TFloat(f): EFloat(Std.string(f));
            case TString(s): EString(s);
            case TBool(b): EAtom(b ? "true" : "false");
            case TNull: ENil;
            case TThis: {
                // In methods, 'this' becomes the receiver parameter
                if (context.currentReceiverParamName != null) {
                    EVar(context.currentReceiverParamName);
                } else {
                    EVar("self");
                }
            }
            case TSuper: EVar("super"); // Will be transformed later if needed
        }
    }

    /**
     * Build local variable references
     *
     * WHY: Variables need context-aware naming resolution
     * WHAT: Converts TLocal nodes to ElixirAST variable references
     * HOW: Checks multiple naming sources in priority order
     */
    public static function buildLocal(v: TVar, context: CompilationContext): ElixirASTDef {
        var varName = v.name;

        // Priority 1: Check pattern variable registry
        if (context.patternVariableRegistry.exists(v.id)) {
            varName = context.patternVariableRegistry.get(v.id);
        }
        // Priority 2: Check clause context for alpha-renaming
        else if (context.currentClauseContext != null) {
            var mapping = context.currentClauseContext.localToName;
            if (mapping != null && mapping.exists(v.id)) {
                varName = mapping.get(v.id);
            }
        }
        // Priority 3: Check temp variable renaming
        else if (context.tempVarRenameMap.exists(Std.string(v.id))) {
            varName = context.tempVarRenameMap.get(Std.string(v.id));
        }

        // Apply underscore prefix for unused variables
        if (shouldPrefixWithUnderscore(v, context)) {
            varName = "_" + varName;
        }

        // Convert to snake_case
        varName = toElixirVarName(varName);

        return EVar(varName);
    }

    /**
     * Build binary operations
     *
     * WHY: Binary operations are fundamental to expressions
     * WHAT: Converts TBinop nodes to ElixirAST binary operations
     * HOW: Maps Haxe operators to Elixir equivalents
     */
    public static function buildBinop(op: Binop): EBinaryOperator {
        return switch(op) {
            case OpAdd: Add;
            case OpMult: Multiply;
            case OpDiv: Divide;
            case OpSub: Subtract;
            case OpAssign: Match;
            case OpEq: Equal;
            case OpNotEq: NotEqual;
            case OpGt: Greater;
            case OpGte: GreaterEqual;
            case OpLt: Less;
            case OpLte: LessEqual;
            case OpAnd: error("Use OpBoolAnd");
            case OpOr: error("Use OpBoolOr");
            case OpXor: BitwiseXor;
            case OpBoolAnd: And;
            case OpBoolOr: Or;
            case OpShl: BitwiseLeftShift;
            case OpShr: BitwiseRightShift;
            case OpUShr: BitwiseRightShift; // No unsigned in Elixir
            case OpMod: Modulo;
            case OpInterval: Range;
            case OpArrow: error("Arrow operator not supported");
            case OpIn: In;
            case OpNullCoal: error("Use null coalescing pattern");
            case OpAssignOp(op): error("Use compound assignment pattern");
        }
    }

    /**
     * Build unary operations
     *
     * WHY: Unary operations modify single expressions
     * WHAT: Converts TUnop nodes to ElixirAST unary operations
     * HOW: Maps prefix/postfix operators appropriately
     */
    public static function buildUnop(op: Unop, postFix: Bool): EUnaryOperator {
        return switch(op) {
            case OpIncrement: error("Use increment pattern");
            case OpDecrement: error("Use decrement pattern");
            case OpNot: Not;
            case OpNeg: Negate;
            case OpNegBits: BitwiseNot;
            case OpSpread: error("Use spread pattern");
        }
    }

    // Helper functions

    static function shouldPrefixWithUnderscore(v: TVar, context: CompilationContext): Bool {
        // Check if marked as unused
        if (context.underscorePrefixedVars.exists(v.id)) {
            return context.underscorePrefixedVars.get(v.id);
        }

        // Check usage map
        if (context.variableUsageMap != null) {
            var isUsed = context.variableUsageMap.exists(v.id) &&
                         context.variableUsageMap.get(v.id);
            return !isUsed;
        }

        return false;
    }

    static function toElixirVarName(name: String): String {
        // Convert camelCase to snake_case
        // This is a simplified version - full implementation would be more robust
        var result = "";
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (i > 0 && char == char.toUpperCase() && char != "_") {
                result += "_" + char.toLowerCase();
            } else {
                result += char.toLowerCase();
            }
        }
        return result;
    }

    static function error(msg: String): Dynamic {
        throw 'CoreExprBuilder: $msg';
        return null;
    }
}

#end