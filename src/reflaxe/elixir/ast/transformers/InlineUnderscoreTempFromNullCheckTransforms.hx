package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.EBinaryOp;
import reflaxe.elixir.ast.ElixirAST.EUnaryOp;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * InlineUnderscoreTempFromNullCheckTransforms
 *
 * WHAT
 * - Detects if-expressions where:
 *   - Condition checks `not Kernel.is_nil(X)` or `X != nil`
 *   - Then-branch contains ERaw with `_this` (or other underscore temps)
 *   - The temp var is never assigned
 * - Replaces the temp var reference with the expression from the null check
 *
 * WHY
 * - When Haxe inlines `extern inline` methods with `__elixir__()`, it creates
 *   temp variables like `_this` to hold the `this` parameter. But when the
 *   inline is inside a conditional, the assignment may be lost while the
 *   reference persists.
 * - This causes "undefined variable _this" errors in Elixir.
 *
 * HOW
 * - For each EIf node:
 *   1. Extract the expression X from `not Kernel.is_nil(X)` or `X != nil` conditions
 *   2. Scan the then-branch for ERaw nodes containing `_this` (or similar)
 *   3. Substitute `_this` with the string representation of X
 *
 * EXAMPLES
 * Haxe:
 *   var title = t.title != null ? t.title.toLowerCase() : "";
 * Before:
 *   title = if (not Kernel.is_nil(t.title)) do
 *     String.downcase(_this)
 *   else
 *     ""
 *   end
 * After:
 *   title = if (not Kernel.is_nil(t.title)) do
 *     String.downcase(t.title)
 *   else
 *     ""
 *   end
 */
class InlineUnderscoreTempFromNullCheckTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EIf(cond, thenBranch, elseBranch):
                    #if debug_underscore_temp_null_check
                    trace("[InlineUnderscoreTempFromNullCheck] Found EIf node");
                    #end
                    // Try to extract expression from null check condition
                    var checkedExpr = extractNullCheckExpr(cond);
                    #if debug_underscore_temp_null_check
                    trace('[InlineUnderscoreTempFromNullCheck] checkedExpr = ' + checkedExpr);
                    #end
                    if (checkedExpr != null) {
                        // We have a null check - look for _this in then-branch
                        var newThen = substituteUnderscoreTemp(thenBranch, checkedExpr);
                        if (newThen != thenBranch) {
                            makeASTWithMeta(EIf(cond, newThen, elseBranch), n.metadata, n.pos);
                        } else {
                            n;
                        }
                    } else {
                        n;
                    }
                default: n;
            }
        });
    }

    /**
     * Extract the expression being checked for null from conditions like:
     * - `not Kernel.is_nil(X)` -> X
     * - `X != nil` -> X
     * - `not Kernel.is_nil(X) and ...` -> X (from first clause)
     */
    static function extractNullCheckExpr(cond: ElixirAST): Null<String> {
        if (cond == null || cond.def == null) return null;
        return switch (cond.def) {
            // Pattern: not Kernel.is_nil(X)
            case EUnary(Not, inner):
                switch (inner.def) {
                    case ERemoteCall({def: EVar("Kernel")}, "is_nil", args) if (args != null && args.length == 1):
                        astToString(args[0]);
                    default: null;
                }
            // Pattern: (not Kernel.is_nil(X)) - with parens as EBlock
            case EBlock(exprs) if (exprs != null && exprs.length == 1):
                extractNullCheckExpr(exprs[0]);
            // Pattern: (not Kernel.is_nil(X)) - with parens as EParen
            case EParen(inner):
                extractNullCheckExpr(inner);
            // Pattern: X != nil
            case EBinary(NotEqual, left, right):
                if (isNil(right)) astToString(left);
                else if (isNil(left)) astToString(right);
                else null;
            // Pattern: not Kernel.is_nil(X) and Y - extract from first condition
            case EBinary(And, left, _):
                extractNullCheckExpr(left);
            default: null;
        };
    }

    static inline function isNil(ast: ElixirAST): Bool {
        if (ast == null || ast.def == null) return false;
        return switch (ast.def) {
            case ENil: true;
            case EAtom(a): a == "nil";
            default: false;
        };
    }

    /**
     * Convert simple AST to string representation.
     */
    static function astToString(ast: ElixirAST): Null<String> {
        if (ast == null || ast.def == null) return null;
        return switch (ast.def) {
            case EVar(name): name;
            case EField(obj, field):
                var objStr = astToString(obj);
                if (objStr != null) '${objStr}.${field}' else null;
            case EAtom(name): ':${name}';
            case EInteger(val): Std.string(val);
            case EFloat(val): Std.string(val);
            case EString(val): '"${val}"';
            case EBoolean(val): val ? "true" : "false";
            case ENil: "nil";
            default: null;
        };
    }

    /**
     * Substitute underscore temp vars (_this, _this1, etc.) in the AST.
     */
    static function substituteUnderscoreTemp(ast: ElixirAST, replacement: String): ElixirAST {
        if (ast == null || ast.def == null) return ast;
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERaw(code) if (code != null):
                    var newCode = substituteInRaw(code, replacement);
                    if (newCode != code) {
                        makeASTWithMeta(ERaw(newCode), n.metadata, n.pos);
                    } else {
                        n;
                    }
                case ERemoteCall({def: EVar("String")}, "downcase", args) if (args != null && args.length == 1):
                    switch (args[0].def) {
                        case EVar(v) if (isUnderscoreTemp(v)):
                            // Replace _this with the replacement expression
                            makeASTWithMeta(
                                ERemoteCall(
                                    makeAST(EVar("String")),
                                    "downcase",
                                    [makeAST(EVar(replacement))]
                                ),
                                n.metadata,
                                n.pos
                            );
                        default: n;
                    }
                default: n;
            }
        });
    }

    /**
     * Check if a variable name is an underscore temp (like _this, _this1, etc.)
     */
    static inline function isUnderscoreTemp(name: String): Bool {
        if (name == null) return false;
        return name == "_this" || (name.indexOf("_this") == 0 && name.length > 5);
    }

    /**
     * Substitute underscore temp vars in raw code string.
     */
    static function substituteInRaw(code: String, replacement: String): String {
        // List of underscore temps to replace
        var temps = ["_this"];
        var result = code;
        for (temp in temps) {
            result = substituteToken(result, temp, replacement);
        }
        return result;
    }

    /**
     * Substitute a token in string with word-boundary detection.
     */
    static function substituteToken(code: String, from: String, to: String): String {
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
        }

        var result = new StringBuf();
        var idx = 0;
        var lastEnd = 0;

        while (idx < code.length) {
            var pos = code.indexOf(from, idx);
            if (pos == -1) break;

            var before = pos > 0 ? code.charAt(pos - 1) : "";
            var afterIdx = pos + from.length;
            var after = afterIdx < code.length ? code.charAt(afterIdx) : "";

            if (!isIdentChar(before) && !isIdentChar(after)) {
                result.add(code.substring(lastEnd, pos));
                result.add(to);
                lastEnd = afterIdx;
                idx = afterIdx;
            } else {
                idx = pos + 1;
            }
        }

        if (lastEnd > 0) {
            result.add(code.substring(lastEnd));
            return result.toString();
        }
        return code;
    }
}

#end
