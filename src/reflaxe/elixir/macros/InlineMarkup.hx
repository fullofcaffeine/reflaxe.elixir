package reflaxe.elixir.macros;

#if macro

import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;

/**
 * InlineMarkup
 *
 * WHAT
 * - Enables Haxe inline markup (`return <div>...</div>`) as syntax sugar for HXX templates.
 * - Rewrites `@:markup "<tag>...</tag>"` expressions (produced by the parser) into `HXX.hxx("...")`
 *   before typing, so the normal HXX → HEEx pipeline applies.
 *
 * WHY
 * - Haxe represents inline markup as an expression metadata `@:markup` on a string constant.
 * - The typer errors on `@:markup` unless a macro rewrites it beforehand.
 * - We want TSX-like authoring ergonomics while reusing the existing HXX implementation and linters.
 *
 * HOW
 * - `enable()` installs a global `@:build(...)` macro for Elixir builds, gated by:
 *   - `-D hxx_inline_markup` (explicit opt-in), OR
 *   - `-D elixir_output` / `-D target.name=elixir` (normal Elixir builds in this repo).
 * - `build()` walks all field expressions and replaces:
 *     EMeta(name=":markup", innerStringExpr)
 *   with:
 *     HXX.hxx(innerStringExpr)
 *   (or just `innerStringExpr` when already inside `HXX.hxx(...)` / `HXX.block(...)` call args).
 *
 * LIMITATIONS
 * - Haxe's markup lexer requires a valid XML root tag name at the start of the literal. Phoenix
 *   dot-components like `<.form>` cannot be the *root* of an inline markup literal; wrap them
 *   in a normal element (e.g. `<div>...</div>`) when using inline markup.
 */
class InlineMarkup {
    /**
     * enable
     *
     * Adds a global `@:build(...)` macro so inline markup works without requiring per-module annotations.
     */
    public static function enable(): Void {
        // Keep this macro safe for non-Elixir targets: only enable when explicitly opted in
        // or when this is clearly an Elixir build.
        var targetName = Context.definedValue("target.name");
        var shouldEnable = Context.defined("hxx_inline_markup") || Context.defined("elixir_output") || targetName == "elixir";
        if (!shouldEnable) return;

        // Apply to types only; fields are rewritten by the build macro itself.
        Compiler.addGlobalMetadata("", "@:build(reflaxe.elixir.macros.InlineMarkup.build())", true, true, false);
    }

    public static macro function build(): Array<Field> {
        var fields = Context.getBuildFields();
        for (f in fields) rewriteField(f);
        return fields;
    }

    static function rewriteField(field: Field): Void {
        if (field == null) return;
        switch (field.kind) {
            case FFun(fn):
                if (fn != null && fn.expr != null) fn.expr = rewriteExpr(fn.expr, false);
            case FVar(t, e):
                if (e != null) field.kind = FVar(t, rewriteExpr(e, false));
            case FProp(get, set, t, e):
                if (e != null) field.kind = FProp(get, set, t, rewriteExpr(e, false));
        }
    }

    static function isHxxCallee(expr: Expr, name: String): Bool {
        if (expr == null || expr.expr == null) return false;
        return switch (expr.expr) {
            case EField(owner, fieldName):
                if (fieldName != name) return false;
                switch (owner.expr) {
                    case EConst(CIdent("HXX")):
                        true;
                    default:
                        false;
                }
            case EMeta(_, inner):
                isHxxCallee(inner, name);
            case EParenthesis(inner):
                isHxxCallee(inner, name);
            default:
                false;
        };
    }

    static function rewriteExpr(expr: Expr, insideHxxArgs: Bool): Expr {
        if (expr == null || expr.expr == null) return expr;
        return switch (expr.expr) {
            case EMeta(meta, inner) if (meta != null && meta.name == ":markup"):
                // Haxe parser encodes markup as `@:markup "<xml...>"`.
                // If we're already inside `HXX.hxx(...)` / `HXX.block(...)` call args, just strip the metadata.
                if (insideHxxArgs) {
                    rewriteExpr(inner, insideHxxArgs);
                } else {
                    var stripped = rewriteExpr(inner, true);
                    mkHxxCall(stripped, expr.pos);
                }
            case ECall(fn, args):
                var nextInside = insideHxxArgs || isHxxCallee(fn, "hxx") || isHxxCallee(fn, "block");
                var nextFn = rewriteExpr(fn, insideHxxArgs);
                var nextArgs = args == null ? null : [for (a in args) rewriteExpr(a, nextInside)];
                { expr: ECall(nextFn, nextArgs), pos: expr.pos };
            case EBlock(exprs):
                { expr: EBlock(exprs == null ? null : [for (e in exprs) rewriteExpr(e, insideHxxArgs)]), pos: expr.pos };
            case EIf(cond, eThen, eElse):
                {
                    expr: EIf(rewriteExpr(cond, insideHxxArgs), rewriteExpr(eThen, insideHxxArgs), eElse == null ? null : rewriteExpr(eElse, insideHxxArgs)),
                    pos: expr.pos
                };
            case ESwitch(target, cases, def):
                var nextCases = cases == null ? null : [
                    for (c in cases) {
                        var nextValues = c.values == null ? null : [for (v in c.values) rewriteExpr(v, insideHxxArgs)];
                        {
                            values: nextValues,
                            guard: c.guard == null ? null : rewriteExpr(c.guard, insideHxxArgs),
                            expr: c.expr == null ? null : rewriteExpr(c.expr, insideHxxArgs)
                        };
                    }
                ];
                {
                    expr: ESwitch(rewriteExpr(target, insideHxxArgs), nextCases, def == null ? null : rewriteExpr(def, insideHxxArgs)),
                    pos: expr.pos
                };
            case EWhile(cond, body, normalWhile):
                { expr: EWhile(rewriteExpr(cond, insideHxxArgs), rewriteExpr(body, insideHxxArgs), normalWhile), pos: expr.pos };
            case EFor(it, body):
                { expr: EFor(rewriteExpr(it, insideHxxArgs), rewriteExpr(body, insideHxxArgs)), pos: expr.pos };
            case ETry(e, catches):
                var nextCatches = catches == null ? null : [
                    for (c in catches) {
                        {
                            name: c.name,
                            type: c.type,
                            expr: c.expr == null ? null : rewriteExpr(c.expr, insideHxxArgs)
                        };
                    }
                ];
                { expr: ETry(rewriteExpr(e, insideHxxArgs), nextCatches), pos: expr.pos };
            case EBinop(op, a, b):
                { expr: EBinop(op, rewriteExpr(a, insideHxxArgs), rewriteExpr(b, insideHxxArgs)), pos: expr.pos };
            case EUnop(op, postFix, a):
                { expr: EUnop(op, postFix, rewriteExpr(a, insideHxxArgs)), pos: expr.pos };
            case EParenthesis(a):
                { expr: EParenthesis(rewriteExpr(a, insideHxxArgs)), pos: expr.pos };
            case EArray(a, b):
                { expr: EArray(rewriteExpr(a, insideHxxArgs), rewriteExpr(b, insideHxxArgs)), pos: expr.pos };
            case EObjectDecl(fields):
                {
                    expr: EObjectDecl(fields == null ? null : [for (f in fields) { field: f.field, expr: rewriteExpr(f.expr, insideHxxArgs) }]),
                    pos: expr.pos
                };
            case EArrayDecl(values):
                { expr: EArrayDecl(values == null ? null : [for (v in values) rewriteExpr(v, insideHxxArgs)]), pos: expr.pos };
            case ENew(t, params):
                { expr: ENew(t, params == null ? null : [for (p in params) rewriteExpr(p, insideHxxArgs)]), pos: expr.pos };
            case EField(owner, name):
                { expr: EField(rewriteExpr(owner, insideHxxArgs), name), pos: expr.pos };
            case ECast(e, t):
                { expr: ECast(e == null ? null : rewriteExpr(e, insideHxxArgs), t), pos: expr.pos };
            case ECheckType(e, t):
                { expr: ECheckType(rewriteExpr(e, insideHxxArgs), t), pos: expr.pos };
            case ETernary(cond, e1, e2):
                { expr: ETernary(rewriteExpr(cond, insideHxxArgs), rewriteExpr(e1, insideHxxArgs), rewriteExpr(e2, insideHxxArgs)), pos: expr.pos };
            case EReturn(e):
                { expr: EReturn(e == null ? null : rewriteExpr(e, insideHxxArgs)), pos: expr.pos };
            case EThrow(e):
                { expr: EThrow(rewriteExpr(e, insideHxxArgs)), pos: expr.pos };
            case EFunction(kind, fn):
                if (fn == null || fn.expr == null) expr;
                else {
                    var nextFn = { args: fn.args, expr: rewriteExpr(fn.expr, insideHxxArgs), params: fn.params, ret: fn.ret };
                    { expr: EFunction(kind, nextFn), pos: expr.pos };
                }
            case EVars(vars):
                {
                    expr: EVars(vars == null ? null : [for (v in vars) { name: v.name, type: v.type, expr: v.expr == null ? null : rewriteExpr(v.expr, insideHxxArgs) }]),
                    pos: expr.pos
                };
            default:
                expr;
        };
    }

    static function mkHxxCall(arg: Expr, pos: Position): Expr {
        var callee: Expr = { expr: EField({ expr: EConst(CIdent("HXX")), pos: pos }, "hxx"), pos: pos };
        return { expr: ECall(callee, [arg]), pos: pos };
    }
}

#end
