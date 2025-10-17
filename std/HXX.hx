package ;

import haxe.macro.Expr;

/**
 * HXX entrypoint (compile-time only)
 *
 * WHAT
 * - Thin forwarder so user code can call `HXX.hxx(...)` and `HXX.block(...)`
 *   without caring about the macro implementation location.
 *
 * HOW
 * - Delegates to `reflaxe.elixir.macros.HXX` which performs validation and
 *   returns a string literal tagged with `@:heex` for the AST builder.
 */
class HXX {
    public static macro function hxx(templateStr: Expr): Expr {
        return reflaxe.elixir.macros.HXX.hxx(templateStr);
    }

    public static macro function block(content: Expr): Expr {
        return reflaxe.elixir.macros.HXX.block(content);
    }
}

