package reflaxe.elixir.macros;

#if macro

import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;

/**
 * InlineMarkup
 *
 * WHAT
 * - Enables Haxe inline markup (`return <div>...</div>`) as syntax sugar for Phoenix HEEx templates.
 * - Rewrites `@:markup "<tag>...</tag>"` expressions (produced by the parser) into a stable
 *   compiler-intercepted call shape: `phoenix.hxx.HeexTemplate.root(<template-expr>)`.
 * - Parses `${ ... }` segments inside inline markup payloads into real Haxe `Expr` nodes, so the
 *   typer checks syntax + types and the backend compiles the expressions into valid Elixir.
 *
 * WHY
 * - Haxe represents inline markup as an expression metadata `@:markup` on a string constant.
 * - The typer errors on `@:markup` unless a macro rewrites it beforehand.
 * - Inline markup payloads are otherwise just text, and `${...}` would be handled via string rewrite
 *   heuristics instead of type-checked compilation.
 *
 * HOW
 * - `enable()` installs a global `@:build(...)` macro (default-on) unless opted out via:
 *   - `-D hxx_no_inline_markup`
 * - `build()` walks all field expressions and replaces:
 *     EMeta(name=":markup", innerStringExpr)
 *   with:
 *     phoenix.hxx.HeexTemplate.root(<template-expr>)
 *   (or just `<template-expr>` when already inside `HeexTemplate.root(...)` / `HXX.hxx(...)` / `HXX.block(...)` args).
 *
 * DEFAULTS / OPT-OUT / LEGACY
 * - Default-on for Phoenix-facing modules (same gating as before).
 * - Opt-out per module: `@:hxx_no_inline_markup`
 * - Global opt-out: `-D hxx_no_inline_markup`
 * - Legacy escape hatch: `@:hxx_legacy` forces the old rewrite to `HXX.hxx(<string-literal>)`
 *   (and keeps `${...}` segments as text for the legacy HXX parser).
 *
 * LIMITATIONS
 * - Haxe's markup lexer requires a valid XML root tag name at the start of the literal. Phoenix
 *   dot-components like `<.form>` cannot be the *root* of an inline markup literal; wrap them
 *   in a normal element (e.g. `<div>...</div>`) when using inline markup.
 * - Haxe 4 inline markup does not support fragment roots (`<> ... </>`).
 */
class InlineMarkup {
    /**
     * enable
     *
     * Adds a global `@:build(...)` macro so inline markup works without requiring per-module annotations.
     */
    public static function enable(): Void {
        // Default-on with explicit global opt-out.
        if (Context.defined("hxx_no_inline_markup")) return;

        // Apply to types only; fields are rewritten by the build macro itself.
        Compiler.addGlobalMetadata("", "@:build(reflaxe.elixir.macros.InlineMarkup.build())", true, true, false);
    }

    public static macro function build(): Array<Field> {
        var fields = Context.getBuildFields();
        if (!shouldProcessLocalType()) return fields;
        for (f in fields) rewriteField(f);
        return fields;
    }

    static function localTypeUsesLegacyRewrite(): Bool {
        var localClassRef = Context.getLocalClass();
        if (localClassRef == null) return false;
        var cls = localClassRef.get();
        if (cls == null || cls.meta == null) return false;
        return cls.meta.has(":hxx_legacy") || cls.meta.has("hxx_legacy");
    }

    static function shouldProcessLocalType(): Bool {
        if (Context.defined("hxx_no_inline_markup")) return false;

        var localClassRef = Context.getLocalClass();
        if (localClassRef == null) return false;
        var cls = localClassRef.get();
        if (cls == null || cls.meta == null) return false;

        // Per-module opt-out (even for Phoenix-facing modules).
        if (cls.meta.has(":hxx_no_inline_markup") || cls.meta.has("hxx_no_inline_markup")) return false;

        // Default: only process Phoenix-facing modules where inline markup is likely to be used.
        // Users can opt-in on a per-module basis with `@:hxx_inline_markup`.
        if (cls.meta.has(":hxx_inline_markup")) return true;

        return cls.meta.has(":liveview")
            || cls.meta.has(":component")
            || cls.meta.has(":controller")
            || cls.meta.has(":channel")
            || cls.meta.has(":endpoint")
            || cls.meta.has(":router")
            || cls.meta.has(":presence")
            || cls.meta.has(":socket")
            || cls.meta.has(":phoenix.components");
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

    static function isHeexTemplateRootCallee(expr: Expr): Bool {
        if (expr == null || expr.expr == null) return false;
        return switch (expr.expr) {
            case EField(owner, fieldName) if (fieldName == "root"):
                switch (owner.expr) {
                    case EConst(CIdent("HeexTemplate")):
                        true;
                    // Allow the fully-qualified type path to appear as an identifier (depends on AST shape).
                    case EConst(CIdent("phoenix.hxx.HeexTemplate")):
                        true;
                    // Legacy: accept old entrypoint names.
                    case EConst(CIdent("HXX2")):
                        true;
                    // Allow the fully-qualified type path to appear as an identifier (depends on AST shape).
                    case EConst(CIdent("phoenix.hxx.HXX2")):
                        true;
                    default:
                        false;
                }
            case EMeta(_, inner):
                isHeexTemplateRootCallee(inner);
            case EParenthesis(inner):
                isHeexTemplateRootCallee(inner);
            default:
                false;
        };
    }

    static function makeSubPos(base: Position, startOffset: Int, endOffset: Int): Position {
        var info = Context.getPosInfos(base);
        var min = info.min + (startOffset < 0 ? 0 : startOffset);
        var max = info.min + (endOffset < startOffset ? startOffset : endOffset);
        // Best-effort: clamp to original span when possible.
        if (max > info.max) max = info.max;
        if (min > info.max) min = info.max;
        return Context.makePosition({ file: info.file, min: min, max: max });
    }

    static function parseInlineMarkupPayloadToTypedExpr(payload: String, payloadPos: Position): Expr {
        if (payload == null || payload.length == 0) {
            return macro $v{payload == null ? "" : payload};
        }

        inline function mkConstString(s: String, pos: Position): Expr {
            return { expr: EConst(CString(s, null)), pos: pos };
        }

        inline function mkAdd(a: Expr, b: Expr, pos: Position): Expr {
            return { expr: EBinop(OpAdd, a, b), pos: pos };
        }

        var parts: Array<Expr> = [];
        var literalStart = 0;
        var index = 0;
        while (index < payload.length) {
            var ch = payload.charAt(index);
            if (ch == "$" && index + 1 < payload.length && payload.charAt(index + 1) == "{") {
                // Flush preceding literal.
                if (index > literalStart) {
                    var lit = payload.substr(literalStart, index - literalStart);
                    parts.push(mkConstString(lit, makeSubPos(payloadPos, literalStart, index)));
                }

                var exprOpenIndex = index; // points at '$'
                var exprStart = index + 2; // after ${
                var cursor = exprStart;
                var depth = 1;
                var inS = false;
                var inD = false;
                var escaped = false;
                while (cursor < payload.length && depth > 0) {
                    var cj = payload.charAt(cursor);
                    if (inS || inD) {
                        if (!escaped && cj == "\\") {
                            escaped = true;
                            cursor++;
                            continue;
                        }
                        if (!escaped) {
                            if (inD && cj == "\"") inD = false;
                            else if (inS && cj == "'") inS = false;
                        } else {
                            escaped = false;
                        }
                        cursor++;
                        continue;
                    }

                    if (cj == "\"") { inD = true; cursor++; continue; }
                    if (cj == "'") { inS = true; cursor++; continue; }

                    if (cj == "{") depth++;
                    else if (cj == "}") depth--;
                    cursor++;
                }

                if (depth != 0) {
                    Context.error("Inline markup: unterminated `${ ... }` expression. Close the `}` or opt out with `-D hxx_no_inline_markup` / `@:hxx_no_inline_markup`.", makeSubPos(payloadPos, exprOpenIndex, payload.length));
                }

                var exprEndExclusive = cursor - 1;
                var rawInner = payload.substr(exprStart, exprEndExclusive - exprStart);
                var trimmed = StringTools.trim(rawInner);
                if (trimmed.length == 0) {
                    Context.error("Inline markup: empty `${}` expression is not allowed.", makeSubPos(payloadPos, exprOpenIndex, cursor));
                }

                var exprPos = makeSubPos(payloadPos, exprStart, exprEndExclusive);
                var parsed = Context.parseInlineString(trimmed, exprPos);
                parts.push({ expr: EParenthesis(parsed), pos: exprPos });

                index = cursor;
                literalStart = index;
                continue;
            }
            index++;
        }

        // Trailing literal.
        if (literalStart < payload.length) {
            parts.push(mkConstString(payload.substr(literalStart), makeSubPos(payloadPos, literalStart, payload.length)));
        }

        if (parts.length == 0) {
            return mkConstString("", payloadPos);
        }
        if (parts.length == 1) {
            return parts[0];
        }

        var acc = parts[0];
        for (i in 1...parts.length) {
            acc = mkAdd(acc, parts[i], payloadPos);
        }
        return acc;
    }

    static function rewriteExpr(expr: Expr, insideHxxArgs: Bool): Expr {
        if (expr == null || expr.expr == null) return expr;

        inline function mk(next: ExprDef): Expr return { expr: next, pos: expr.pos };

        function mapArray<T>(arr: Array<T>, mapFn: (T) -> T): Array<T> {
            if (arr == null) return null;
            var changed = false;
            var out: Array<T> = null;
            for (i in 0...arr.length) {
                var v = arr[i];
                var nv = mapFn(v);
                if (!changed && nv != v) {
                    changed = true;
                    out = arr.copy();
                }
                if (changed) out[i] = nv;
            }
            return changed ? out : arr;
        }

        return switch (expr.expr) {
            case EMeta(meta, inner) if (meta != null && meta.name == ":markup"):
                // Haxe parser encodes markup as `@:markup "<xml...>"`.
                var legacy = localTypeUsesLegacyRewrite();
                // Legacy escape hatch: preserve old behavior (wrap the raw payload string in HXX.hxx).
                if (legacy) {
                    if (insideHxxArgs) {
                        rewriteExpr(inner, insideHxxArgs);
                    } else {
                        var strippedLegacy = rewriteExpr(inner, true);
                        mkHxxCall(strippedLegacy, expr.pos);
                    }
                } else {
                    // Default path: parse `${ ... }` segments into real Haxe expressions.
                    var rewrittenInner = rewriteExpr(inner, insideHxxArgs);
                    var payloadExpr = switch (rewrittenInner.expr) {
                        case EConst(CString(s, _)):
                            // Parse `${ ... }` segments into real Haxe Expr nodes, then rewrite nested inline markup
                            // inside those expressions as well (so `${ if (...) <div/> else <span/> }` works).
                            //
                            // IMPORTANT: treat nested markup as "inside template producer args" so we do not wrap
                            // nested literals in `HeexTemplate.root(...)` again.
                            rewriteExpr(parseInlineMarkupPayloadToTypedExpr(s, rewrittenInner.pos), true);
                        default:
                            Context.error("Inline markup: expected a constant string payload from the parser.", rewrittenInner.pos);
                    }

                    // If we're already inside a template producer call, just strip `@:markup` and keep the argument expression.
                    if (insideHxxArgs) {
                        payloadExpr;
                    } else {
                        mkHeexTemplateRootCall(payloadExpr, expr.pos);
                    }
                }
            case EMeta(meta, inner):
                var nextInner = rewriteExpr(inner, insideHxxArgs);
                if (nextInner == inner) expr else mk(EMeta(meta, nextInner));
            case ECall(fn, args):
                var nextInside = insideHxxArgs || isHxxCallee(fn, "hxx") || isHxxCallee(fn, "block") || isHeexTemplateRootCallee(fn);
                var nextFn = rewriteExpr(fn, insideHxxArgs);
                var nextArgs = args == null ? null : mapArray(args, (a) -> rewriteExpr(a, nextInside));
                if (nextFn == fn && nextArgs == args) expr else mk(ECall(nextFn, nextArgs));
            case EBlock(exprs):
                var next = exprs == null ? null : mapArray(exprs, (e) -> rewriteExpr(e, insideHxxArgs));
                if (next == exprs) expr else mk(EBlock(next));
            case EIf(cond, eThen, eElse):
                var rewrittenCond = rewriteExpr(cond, insideHxxArgs);
                var rewrittenThen = rewriteExpr(eThen, insideHxxArgs);
                var rewrittenElse = eElse == null ? null : rewriteExpr(eElse, insideHxxArgs);
                if (rewrittenCond == cond && rewrittenThen == eThen && rewrittenElse == eElse) expr else mk(EIf(rewrittenCond, rewrittenThen, rewrittenElse));
            case ESwitch(target, cases, def):
                var rewrittenTarget = rewriteExpr(target, insideHxxArgs);
                var rewrittenDefault = def == null ? null : rewriteExpr(def, insideHxxArgs);
                var rewrittenCases = cases == null ? null : mapArray(cases, (c) -> {
                    if (c == null) return c;
                    var rewrittenValues = c.values == null ? null : mapArray(c.values, (v) -> rewriteExpr(v, insideHxxArgs));
                    var rewrittenGuard = c.guard == null ? null : rewriteExpr(c.guard, insideHxxArgs);
                    var rewrittenExpr = c.expr == null ? null : rewriteExpr(c.expr, insideHxxArgs);
                    if (rewrittenValues == c.values && rewrittenGuard == c.guard && rewrittenExpr == c.expr) c else { values: rewrittenValues, guard: rewrittenGuard, expr: rewrittenExpr };
                });
                if (rewrittenTarget == target && rewrittenCases == cases && rewrittenDefault == def) expr else mk(ESwitch(rewrittenTarget, rewrittenCases, rewrittenDefault));
            case EWhile(cond, body, normalWhile):
                var rewrittenCond = rewriteExpr(cond, insideHxxArgs);
                var rewrittenBody = rewriteExpr(body, insideHxxArgs);
                if (rewrittenCond == cond && rewrittenBody == body) expr else mk(EWhile(rewrittenCond, rewrittenBody, normalWhile));
            case EFor(it, body):
                var rewrittenIterator = rewriteExpr(it, insideHxxArgs);
                var rewrittenBody = rewriteExpr(body, insideHxxArgs);
                if (rewrittenIterator == it && rewrittenBody == body) expr else mk(EFor(rewrittenIterator, rewrittenBody));
            case ETry(e, catches):
                var rewrittenTryExpr = rewriteExpr(e, insideHxxArgs);
                var rewrittenCatches = catches == null ? null : mapArray(catches, (c) -> {
                    if (c == null) return c;
                    var rewrittenCatchExpr = c.expr == null ? null : rewriteExpr(c.expr, insideHxxArgs);
                    if (rewrittenCatchExpr == c.expr) c else { name: c.name, type: c.type, expr: rewrittenCatchExpr };
                });
                if (rewrittenTryExpr == e && rewrittenCatches == catches) expr else mk(ETry(rewrittenTryExpr, rewrittenCatches));
            case EBinop(op, a, b):
                var rewrittenLeft = rewriteExpr(a, insideHxxArgs);
                var rewrittenRight = rewriteExpr(b, insideHxxArgs);
                if (rewrittenLeft == a && rewrittenRight == b) expr else mk(EBinop(op, rewrittenLeft, rewrittenRight));
            case EUnop(op, postFix, a):
                var rewrittenOperand = rewriteExpr(a, insideHxxArgs);
                if (rewrittenOperand == a) expr else mk(EUnop(op, postFix, rewrittenOperand));
            case EParenthesis(a):
                var rewrittenInner = rewriteExpr(a, insideHxxArgs);
                if (rewrittenInner == a) expr else mk(EParenthesis(rewrittenInner));
            case EArray(a, b):
                var rewrittenArray = rewriteExpr(a, insideHxxArgs);
                var rewrittenIndex = rewriteExpr(b, insideHxxArgs);
                if (rewrittenArray == a && rewrittenIndex == b) expr else mk(EArray(rewrittenArray, rewrittenIndex));
            case EObjectDecl(fields):
                var rewrittenFields = fields == null ? null : mapArray(fields, (f) -> {
                    var rewrittenFieldExpr = rewriteExpr(f.expr, insideHxxArgs);
                    if (rewrittenFieldExpr == f.expr) f else { field: f.field, expr: rewrittenFieldExpr };
                });
                if (rewrittenFields == fields) expr else mk(EObjectDecl(rewrittenFields));
            case EArrayDecl(values):
                var rewrittenValues = values == null ? null : mapArray(values, (v) -> rewriteExpr(v, insideHxxArgs));
                if (rewrittenValues == values) expr else mk(EArrayDecl(rewrittenValues));
            case ENew(t, params):
                var rewrittenParams = params == null ? null : mapArray(params, (p) -> rewriteExpr(p, insideHxxArgs));
                if (rewrittenParams == params) expr else mk(ENew(t, rewrittenParams));
            case EField(owner, name):
                var rewrittenOwner = rewriteExpr(owner, insideHxxArgs);
                if (rewrittenOwner == owner) expr else mk(EField(rewrittenOwner, name));
            case ECast(e, t):
                var rewrittenExpr = e == null ? null : rewriteExpr(e, insideHxxArgs);
                if (rewrittenExpr == e) expr else mk(ECast(rewrittenExpr, t));
            case ECheckType(e, t):
                var rewrittenExpr = rewriteExpr(e, insideHxxArgs);
                if (rewrittenExpr == e) expr else mk(ECheckType(rewrittenExpr, t));
            case ETernary(cond, thenExpr, elseExpr):
                var rewrittenCond = rewriteExpr(cond, insideHxxArgs);
                var rewrittenThenExpr = rewriteExpr(thenExpr, insideHxxArgs);
                var rewrittenElseExpr = rewriteExpr(elseExpr, insideHxxArgs);
                if (rewrittenCond == cond && rewrittenThenExpr == thenExpr && rewrittenElseExpr == elseExpr) expr else mk(ETernary(rewrittenCond, rewrittenThenExpr, rewrittenElseExpr));
            case EReturn(e):
                var rewrittenExpr = e == null ? null : rewriteExpr(e, insideHxxArgs);
                if (rewrittenExpr == e) expr else mk(EReturn(rewrittenExpr));
            case EThrow(e):
                var rewrittenExpr = rewriteExpr(e, insideHxxArgs);
                if (rewrittenExpr == e) expr else mk(EThrow(rewrittenExpr));
            case EFunction(kind, fn):
                if (fn == null || fn.expr == null) expr;
                else {
                    var rewrittenBody = rewriteExpr(fn.expr, insideHxxArgs);
                    if (rewrittenBody == fn.expr) expr else mk(EFunction(kind, { args: fn.args, expr: rewrittenBody, params: fn.params, ret: fn.ret }));
                }
            case EVars(vars):
                var rewrittenVars = vars == null ? null : mapArray(vars, (v) -> {
                    if (v.expr == null) return v;
                    var rewrittenInit = rewriteExpr(v.expr, insideHxxArgs);
                    if (rewrittenInit == v.expr) v else { name: v.name, type: v.type, expr: rewrittenInit };
                });
                if (rewrittenVars == vars) expr else mk(EVars(rewrittenVars));
            default:
                expr;
        };
    }

    static function mkHxxCall(arg: Expr, pos: Position): Expr {
        var callee: Expr = { expr: EField({ expr: EConst(CIdent("HXX")), pos: pos }, "hxx"), pos: pos };
        return { expr: ECall(callee, [arg]), pos: pos };
    }

    static function mkHeexTemplateRootCall(arg: Expr, pos: Position): Expr {
        var call = macro phoenix.hxx.HeexTemplate.root($arg);
        call.pos = pos;
        return call;
    }
}

#end
