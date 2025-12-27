package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.EBinaryOp;
import reflaxe.elixir.ast.ElixirAST.EUnaryOp;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

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
private enum NonNilBranch {
    Then;
    Else;
}

class InlineUnderscoreTempFromNullCheckTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EIf(cond, thenBranch, elseBranch):
                    #if debug_underscore_temp_null_check
                    // DISABLED: trace("[InlineUnderscoreTempFromNullCheck] Found EIf node");
                    #end
                    // Try to extract expression + which branch guarantees non-nil
                    var checked = extractNonNilExpr(cond);
                    if (checked == null) checked = extractNonNilExprByPrint(cond);
                    #if debug_underscore_temp_null_check
                    // DISABLED: trace('[InlineUnderscoreTempFromNullCheck] checked = ' + checked);
                    #end
                    if (checked == null) return n;

                    // We have a nil check - look for underscore temps in the branch where the value is non-nil
                    return switch (checked.branch) {
                        case Then:
                            var newThen = substituteUnderscoreTemp(thenBranch, checked.expr);
                            newThen != thenBranch ? makeASTWithMeta(EIf(cond, newThen, elseBranch), n.metadata, n.pos) : n;
                        case Else:
                            if (elseBranch == null) return n;
                            var newElse = substituteUnderscoreTemp(elseBranch, checked.expr);
                            newElse != elseBranch ? makeASTWithMeta(EIf(cond, thenBranch, newElse), n.metadata, n.pos) : n;
                    };
                default: n;
            }
        });
    }

    /**
     * Extract the expression being checked for null from conditions like:
     * - `not Kernel.is_nil(X)` -> X
     * - `X != nil` -> X
     * - `Kernel.is_nil(X)` -> X (non-nil is in else-branch)
     * - `X == nil` -> X (non-nil is in else-branch)
     * - `not Kernel.is_nil(X) and ...` -> X (from first clause)
     */
    static function extractNonNilExpr(cond: ElixirAST): Null<{ expr: String, branch: NonNilBranch }> {
        if (cond == null || cond.def == null) return null;
        return switch (cond.def) {
            // Pattern: not Kernel.is_nil(X)
            case EUnary(Not, inner):
                switch (inner.def) {
                    case ERemoteCall({def: EVar("Kernel")}, "is_nil", args) if (args != null && args.length == 1):
                        var expr = astToString(args[0]);
                        expr != null ? {expr: expr, branch: Then} : null;
                    case ECall({def: EVar("Kernel")}, "is_nil", args) if (args != null && args.length == 1):
                        var expr = astToString(args[0]);
                        expr != null ? {expr: expr, branch: Then} : null;
                    case ECall(null, "is_nil", args) if (args != null && args.length == 1):
                        var expr = astToString(args[0]);
                        expr != null ? {expr: expr, branch: Then} : null;
                    default: null;
                }
            // Pattern: Kernel.is_nil(X) (non-nil is else branch)
            case ERemoteCall({def: EVar("Kernel")}, "is_nil", args) if (args != null && args.length == 1):
                var expr = astToString(args[0]);
                expr != null ? {expr: expr, branch: Else} : null;
            case ECall({def: EVar("Kernel")}, "is_nil", args) if (args != null && args.length == 1):
                var expr = astToString(args[0]);
                expr != null ? {expr: expr, branch: Else} : null;
            case ECall(null, "is_nil", args) if (args != null && args.length == 1):
                var expr = astToString(args[0]);
                expr != null ? {expr: expr, branch: Else} : null;
            // Pattern: (Kernel.is_nil(X)) - with parens as EBlock/EParen handled below

            // Fallback: raw condition strings (rare, but can happen when upstream emits ERaw)
            case ERaw(code) if (code != null):
                var trimmed = StringTools.trim(code);
                // Strip one layer of outer parentheses.
                if (StringTools.startsWith(trimmed, "(") && StringTools.endsWith(trimmed, ")")) {
                    trimmed = StringTools.trim(trimmed.substring(1, trimmed.length - 1));
                }

                var rxIsNil = ~/^Kernel\\.is_nil\\(([^\\)]+)\\)$/;
                if (rxIsNil.match(trimmed)) {
                    return {expr: StringTools.trim(rxIsNil.matched(1)), branch: Else};
                }

                var rxNotIsNil = ~/^not\\s+Kernel\\.is_nil\\(([^\\)]+)\\)$/;
                if (rxNotIsNil.match(trimmed)) {
                    return {expr: StringTools.trim(rxNotIsNil.matched(1)), branch: Then};
                }

                null;

            // Pattern: X == nil (non-nil is else branch)
            case EBinary(Equal, left, right):
                if (isNil(right)) {
                    var expr = astToString(left);
                    expr != null ? {expr: expr, branch: Else} : null;
                } else if (isNil(left)) {
                    var expr = astToString(right);
                    expr != null ? {expr: expr, branch: Else} : null;
                } else {
                    null;
                }
            // Pattern: (not Kernel.is_nil(X)) - with parens as EBlock
            case EBlock(exprs) if (exprs != null && exprs.length == 1):
                extractNonNilExpr(exprs[0]);
            // Pattern: (not Kernel.is_nil(X)) - with parens as EParen
            case EParen(inner):
                extractNonNilExpr(inner);
            // Pattern: X != nil
            case EBinary(NotEqual, left, right):
                if (isNil(right)) {
                    var expr = astToString(left);
                    expr != null ? {expr: expr, branch: Then} : null;
                } else if (isNil(left)) {
                    var expr = astToString(right);
                    expr != null ? {expr: expr, branch: Then} : null;
                } else {
                    null;
                }
            // Pattern: not Kernel.is_nil(X) and Y - extract from any clause that guarantees non-nil in THEN
            case EBinary(And, left, _):
                var fromLeft = extractNonNilExpr(left);
                (fromLeft != null && fromLeft.branch == Then) ? fromLeft : null;
            // Pattern: Kernel.is_nil(X) or Y - extract from any clause that guarantees non-nil in ELSE
            case EBinary(Or, left, right):
                var fromLeft = extractNonNilExpr(left);
                if (fromLeft != null && fromLeft.branch == Else) return fromLeft;
                var fromRight = extractNonNilExpr(right);
                (fromRight != null && fromRight.branch == Else) ? fromRight : null;
            default: null;
        };
    }

    /**
     * Last-resort extractor: print the condition AST and match string patterns.
     *
     * WHY
     * - Some upstream shapes (especially around inlined externs) can wrap nil checks
     *   in ways that are cumbersome to match structurally. This is a correctness
     *   safeguard to prevent emitting undefined `_this` temps.
     */
    static function extractNonNilExprByPrint(cond: ElixirAST): Null<{ expr: String, branch: NonNilBranch }> {
        if (cond == null || cond.def == null) return null;
        var printed = StringTools.trim(ElixirASTPrinter.printAST(cond));
        if (StringTools.startsWith(printed, "(") && StringTools.endsWith(printed, ")")) {
            printed = StringTools.trim(printed.substring(1, printed.length - 1));
        }

        var rxIsNil = ~/^Kernel\\.is_nil\\(([^\\)]+)\\)$/;
        if (rxIsNil.match(printed)) return {expr: StringTools.trim(rxIsNil.matched(1)), branch: Else};

        var rxNotIsNil = ~/^not\\s+Kernel\\.is_nil\\(([^\\)]+)\\)$/;
        if (rxNotIsNil.match(printed)) return {expr: StringTools.trim(rxNotIsNil.matched(1)), branch: Then};

        return null;
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
        inline function isSimpleVarName(name: String): Bool {
            return name != null && ~/^[a-zA-Z_][a-zA-Z0-9_]*$/.match(name);
        }
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                // Replace direct references to underscore temps when we can represent the replacement as a var.
                case EVar(v) if (isUnderscoreTemp(v) && isSimpleVarName(replacement)):
                    makeASTWithMeta(EVar(replacement), n.metadata, n.pos);
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
                                    [makeAST(isSimpleVarName(replacement) ? EVar(replacement) : ERaw(replacement))]
                                ),
                                n.metadata,
                                n.pos
                            );
                        default: n;
                    }
                case ECall({def: EVar("String")}, "downcase", args) if (args != null && args.length == 1):
                    switch (args[0].def) {
                        case EVar(v) if (isUnderscoreTemp(v) && isSimpleVarName(replacement)):
                            makeASTWithMeta(ECall(makeAST(EVar("String")), "downcase", [makeAST(EVar(replacement))]), n.metadata, n.pos);
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
