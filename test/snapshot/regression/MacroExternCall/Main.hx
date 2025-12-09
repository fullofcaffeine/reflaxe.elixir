package;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

/**
 * Test that macros can generate calls to extern classes with @:native annotations
 *
 * The problem: When a macro generates:
 *   return macro phoenix.Component.assign($socketExpr, $mapExpr);
 *
 * It compiles to WRONG Elixir:
 *   TodoApp.LiveView.phoenix.component.assign(sock, assigns)
 *
 * Instead of the correct:
 *   Phoenix.Component.assign(sock, assigns)
 *
 * This happens because the macro context doesn't respect the @:native annotation
 * on the phoenix.Component extern class.
 */
@:nullSafety(Off)
class Main {
    #if macro
    static function testMacro(socket: Expr): Expr {
        // Try to generate a call to phoenix.Component.assign
        var assigns = macro {test: "value"};

        // This should generate Phoenix.Component.assign(socket, assigns)
        // but currently generates TodoApp.LiveView.phoenix.component.assign(socket, assigns)
        return macro phoenix.Component.assign($socket, $assigns);
    }
    #end

    static function main() {
        // In a LiveView context
        var socket: Dynamic = null;

        // Call the macro
        var result = testMacro(socket);

        trace("Test completed");
    }
}
