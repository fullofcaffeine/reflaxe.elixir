package reflaxe.elixir.ast.heex;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr.Position;
import haxe.macro.Type.TypedExpr;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.ElixirAST;

/**
 * HeexTsxAstLowerer
 *
 * WHAT
 * - Lowers the TSX template AST (`phoenix.hxx.ast.HeexNode` / `HeexAttr`) into HEEx source.
 *
 * WHY
 * - In TSX mode we don't want to interpret templates as strings (no heuristics).
 * - Macros build a structured AST at compile-time; this module converts that AST into
 *   idiomatic HEEx that Phoenix expects, and the compiler emits it as `~H"""..."""`.
 *
 * HOW
 * - The CallExprBuilder intercepts `phoenix.hxx.HeexTemplate.root_ast(node)` and calls
 *   `lowerRoot/3` on the typed enum constructor tree.
 * - Embedded expressions are compiled through the normal TypedExpr -> ElixirAST path and
 *   injected via `<%= ... %>` or `{...}` attribute expressions.
 *
 * EXAMPLES
 * - Haxe TSX node:
 *   `HeexNode.Element("section", [HeexAttr.Spread(assigns.attrs)], [...])`
 * - Generated HEEx:
 *   `<section {@attrs}>...</section>`
 */
class HeexTsxAstLowerer {
    public static function lowerRoot(
        nodeExpr: TypedExpr,
        buildExpression: (TypedExpr) -> ElixirAST,
        context: CompilationContext
    ): String {
        return lowerNode(unwrap(nodeExpr), buildExpression, context);
    }

    static function unwrap(e: TypedExpr): TypedExpr {
        if (e == null) return e;
        return switch (e.expr) {
            case TMeta(_, inner): unwrap(inner);
            case TParenthesis(inner): unwrap(inner);
            case TCast(inner, _): unwrap(inner);
            default: e;
        };
    }

    static function normalizeAssignsExprString(exprString: String): String {
        if (exprString == null) return "";
        var out = exprString;
        var start = ~/^assigns\.([A-Za-z_][A-Za-z0-9_]*)/;
        if (start.match(out)) {
            out = "@" + start.matched(1) + out.substr(start.matchedPos().len);
        }
        // Replace non-dotted assigns.foo occurrences inside larger expressions, but avoid
        // touching `socket.assigns.foo` or other dotted chains.
        var re = ~/([^A-Za-z0-9_\\.])assigns\\.([A-Za-z_][A-Za-z0-9_]*)/g;
        out = re.map(out, (r) -> r.matched(1) + "@" + r.matched(2));
        return out;
    }

    static function exprToInjectionString(e: TypedExpr, buildExpression: (TypedExpr) -> ElixirAST): String {
        var ast = buildExpression(e);
        var printed = reflaxe.elixir.ast.ElixirASTPrinter.printASTForInjectionSubstitution(ast);
        return normalizeAssignsExprString(printed);
    }

    static function lowerNode(e: TypedExpr, buildExpression: (TypedExpr) -> ElixirAST, context: CompilationContext): String {
        e = unwrap(e);
        if (e == null) {
            context.error("TSX template: expected HeexNode, got null", context.getCurrentPosition());
            throw "tsx_heex_node_null";
        }

        switch (e.expr) {
            case TCall(fn, params):
                var callTarget = unwrap(fn);
                switch (callTarget.expr) {
                    case TField(_, fa):
                        switch (fa) {
                            case FEnum(enumRef, fieldRef):
                                var enumName = enumRef.get().name;
                                var ctor = fieldRef.name;
                                if (enumName == "HeexNode") {
                                    return lowerHeexNodeCtor(ctor, params, buildExpression, context, e.pos);
                                }
                            case FStatic(classRef, cf):
                                var cls = classRef.get();
                                if (cls != null && cls.name == "HeexNode" && cls.pack != null && cls.pack.join(".") == "phoenix.hxx.ast") {
                                    return lowerHeexNodeCtor(cf.get().name, params, buildExpression, context, e.pos);
                                }
                            default:
                        }
                    default:
                }
            case TBlock(exprs):
                if (exprs == null || exprs.length == 0) {
                    context.error("TSX template: empty block where HeexNode is expected", context.getCurrentPosition());
                    throw "tsx_heex_empty_block";
                }
                return lowerNode(exprs[exprs.length - 1], buildExpression, context);
            case TMeta(_, inner):
                return lowerNode(inner, buildExpression, context);
            case TParenthesis(inner):
                return lowerNode(inner, buildExpression, context);
            default:
        }

        context.error(
            "TSX template: expected a phoenix.hxx.ast.HeexNode constructor expression",
            context.getCurrentPosition()
        );
        throw "tsx_heex_node_unexpected_expr";
    }

    static function lowerHeexNodeCtor(
        ctor: String,
        params: Array<TypedExpr>,
        buildExpression: (TypedExpr) -> ElixirAST,
        context: CompilationContext,
        pos: Position
    ): String {
        return switch (ctor) {
            case "Text":
                if (params == null || params.length != 1) {
                    context.error("TSX template: HeexNode.Text expects 1 argument", context.getCurrentPosition());
                    throw "tsx_heex_text_arity";
                }
                switch (unwrap(params[0]).expr) {
                    case TConst(TString(s)):
                        s;
                    default:
                        context.error("TSX template: HeexNode.Text expects a string literal", context.getCurrentPosition());
                        throw "tsx_heex_text_nonliteral";
                }
            case "ExprText":
                if (params == null || params.length != 1) {
                    context.error("TSX template: HeexNode.ExprText expects 1 argument", context.getCurrentPosition());
                    throw "tsx_heex_exprtext_arity";
                }
                "<%= " + exprToInjectionString(params[0], buildExpression) + " %>";
            case "Fragment":
                if (params == null || params.length != 1) {
                    context.error("TSX template: HeexNode.Fragment expects 1 argument", context.getCurrentPosition());
                    throw "tsx_heex_fragment_arity";
                }
                var children = expectArrayExpr(params[0], context);
                var out = "";
                for (c in children) out += lowerNode(c, buildExpression, context);
                out;
            case "Element":
                if (params == null || params.length != 3) {
                    context.error("TSX template: HeexNode.Element expects 3 arguments", context.getCurrentPosition());
                    throw "tsx_heex_element_arity";
                }
                var name = expectStringConst(params[0], context);
                var attrs = expectArrayExpr(params[1], context);
                var children = expectArrayExpr(params[2], context);
                lowerElement(name, attrs, children, buildExpression, context);
            case "If":
                if (params == null || params.length != 3) {
                    context.error("TSX template: HeexNode.If expects 3 arguments", context.getCurrentPosition());
                    throw "tsx_heex_if_arity";
                }
                var condStr = exprToInjectionString(params[0], buildExpression);
                var thenStr = lowerNode(params[1], buildExpression, context);
                var elseExpr = unwrap(params[2]);
                var elseStr = switch (elseExpr.expr) {
                    case TConst(TNull):
                        null;
                    default:
                        lowerNode(elseExpr, buildExpression, context);
                }
                if (elseStr == null) {
                    "<%= if " + condStr + " do %>" + thenStr + "<% end %>";
                } else {
                    "<%= if " + condStr + " do %>" + thenStr + "<% else %>" + elseStr + "<% end %>";
                }
            case "For":
                if (params == null || params.length != 2) {
                    context.error("TSX template: HeexNode.For expects 2 arguments", context.getCurrentPosition());
                    throw "tsx_heex_for_arity";
                }
                var itemsStr = exprToInjectionString(params[0], buildExpression);
                var fnExpr = unwrap(params[1]);
                var binderName: String = null;
                var bodyExpr: TypedExpr = null;
                switch (fnExpr.expr) {
                    case TFunction(fn):
                        if (fn == null || fn.args == null || fn.args.length != 1) {
                            context.error("TSX template: For render fn must take exactly 1 binder arg", context.getCurrentPosition());
                            throw "tsx_heex_for_fn_args";
                        }
                        binderName = fn.args[0].v.name;
                        bodyExpr = extractFunctionBodyExpr(fn.expr, context);
                    default:
                        context.error("TSX template: For render must be a function", context.getCurrentPosition());
                        throw "tsx_heex_for_fn_expected";
                }
                var bodyStr = lowerNode(bodyExpr, buildExpression, context);
                "<%= for " + binderName + " <- " + itemsStr + " do %>" + bodyStr + "<% end %>";
            default:
                context.error('TSX template: unsupported HeexNode constructor "' + ctor + '"', context.getCurrentPosition());
                throw "tsx_heex_unsupported_ctor";
        };
    }

    static function extractFunctionBodyExpr(fnBody: TypedExpr, context: CompilationContext): TypedExpr {
        var b = unwrap(fnBody);
        if (b == null) {
            context.error("TSX template: For render fn body is null", context.getCurrentPosition());
            throw "tsx_heex_for_fn_body_null";
        }
        return switch (b.expr) {
            case TReturn(e):
                var retExpr = unwrap(e);
                if (retExpr == null) {
                    context.error("TSX template: For render fn must return a HeexNode", context.getCurrentPosition());
                    throw "tsx_heex_for_fn_body_return_null";
                }
                retExpr;
            case TBlock(exprs):
                if (exprs == null || exprs.length == 0) {
                    context.error("TSX template: For render fn body is empty", context.getCurrentPosition());
                    throw "tsx_heex_for_fn_body_empty";
                }
                extractFunctionBodyExpr(exprs[exprs.length - 1], context);
            default:
                b;
        };
    }

    static function lowerElement(
        name: String,
        attrs: Array<TypedExpr>,
        children: Array<TypedExpr>,
        buildExpression: (TypedExpr) -> ElixirAST,
        context: CompilationContext
    ): String {
        var attrsStr = lowerAttrs(attrs, buildExpression, context);
        var childrenStr = "";
        for (c in children) childrenStr += lowerNode(c, buildExpression, context);

        if (children.length == 0 && isVoidElement(name)) {
            return "<" + name + attrsStr + " />";
        }
        return "<" + name + attrsStr + ">" + childrenStr + "</" + name + ">";
    }

    static function lowerAttrs(attrs: Array<TypedExpr>, buildExpression: (TypedExpr) -> ElixirAST, context: CompilationContext): String {
        if (attrs == null || attrs.length == 0) return "";
        var out = "";
        for (a in attrs) out += lowerAttr(unwrap(a), buildExpression, context);
        return out;
    }

    static function lowerAttr(a: TypedExpr, buildExpression: (TypedExpr) -> ElixirAST, context: CompilationContext): String {
        if (a == null) return "";
        switch (a.expr) {
            case TCall(fn, params):
                var callTarget = unwrap(fn);
                var ctor: Null<String> = null;
                switch (callTarget.expr) {
                    case TField(_, fa):
                        switch (fa) {
                            case FEnum(enumRef, fieldRef):
                                var enumName = enumRef.get().name;
                                if (enumName == "HeexAttr") {
                                    ctor = fieldRef.name;
                                }
                            case FStatic(classRef, cf):
                                var cls = classRef.get();
                                if (cls != null && cls.name == "HeexAttr" && cls.pack != null && cls.pack.join(".") == "phoenix.hxx.ast") {
                                    ctor = cf.get().name;
                                }
                            default:
                        }
                    default:
                }
                if (ctor != null) {
                    return lowerHeexAttrCtor(ctor, params, buildExpression, context);
                }
            default:
        }

        context.error("TSX template: expected a phoenix.hxx.ast.HeexAttr constructor expression", context.getCurrentPosition());
        throw "tsx_heex_attr_unexpected_expr";
    }

    static function lowerHeexAttrCtor(
        ctor: String,
        params: Array<TypedExpr>,
        buildExpression: (TypedExpr) -> ElixirAST,
        context: CompilationContext
    ): String {
        return switch (ctor) {
            case "Static":
                if (params == null || params.length != 2) {
                    context.error("TSX template: HeexAttr.Static expects 2 args", context.getCurrentPosition());
                    throw "tsx_heex_attr_static_arity";
                }
                var name = expectStringConst(params[0], context);
                var value = expectStringConst(params[1], context);
                " " + name + "=\"" + value + "\"";
            case "Bool":
                if (params == null || params.length != 1) {
                    context.error("TSX template: HeexAttr.Bool expects 1 arg", context.getCurrentPosition());
                    throw "tsx_heex_attr_bool_arity";
                }
                var name = expectStringConst(params[0], context);
                " " + name;
            case "Expr":
                if (params == null || params.length != 2) {
                    context.error("TSX template: HeexAttr.Expr expects 2 args", context.getCurrentPosition());
                    throw "tsx_heex_attr_expr_arity";
                }
                var name = expectStringConst(params[0], context);
                var exprStr = exprToInjectionString(params[1], buildExpression);
                " " + name + "={" + exprStr + "}";
            case "Spread":
                if (params == null || params.length != 1) {
                    context.error("TSX template: HeexAttr.Spread expects 1 arg", context.getCurrentPosition());
                    throw "tsx_heex_attr_spread_arity";
                }
                var spreadExpr = StringTools.trim(exprToInjectionString(params[0], buildExpression));
                if (!StringTools.startsWith(spreadExpr, "@")) {
                    spreadExpr = "@" + spreadExpr;
                }
                " {" + spreadExpr + "}";
            default:
                context.error('TSX template: unsupported HeexAttr ctor "' + ctor + '"', context.getCurrentPosition());
                throw "tsx_heex_attr_unsupported_ctor";
        };
    }

    static function expectArrayExpr(e: TypedExpr, context: CompilationContext): Array<TypedExpr> {
        var u = unwrap(e);
        if (u == null) return [];
        return switch (u.expr) {
            case TArrayDecl(values):
                values == null ? [] : values;
            default:
                context.error("TSX template: expected an array literal", context.getCurrentPosition());
                throw "tsx_heex_expected_array";
        };
    }

    static function expectStringConst(e: TypedExpr, context: CompilationContext): String {
        var u = unwrap(e);
        if (u == null) {
            context.error("TSX template: expected a string literal, got null", context.getCurrentPosition());
            throw "tsx_heex_expected_string_null";
        }
        return switch (u.expr) {
            case TConst(TString(s)):
                s;
            default:
                context.error("TSX template: expected a string literal", context.getCurrentPosition());
                throw "tsx_heex_expected_string";
        };
    }

    static function isVoidElement(name: String): Bool {
        if (name == null) return false;
        return switch (name) {
            case "area" | "base" | "br" | "col" | "embed" | "hr" | "img" | "input" | "link" | "meta" | "param" | "source" | "track" | "wbr":
                true;
            default:
                false;
        };
    }
}

#end
