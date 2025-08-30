// Let's check what AST is being generated for __elixir__ calls
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class DebugAST {
    public static function main() {
        debugCall();
    }
    
    macro static function debugCall() {
        // Create the __elixir__ call expression
        var expr = macro untyped __elixir__("IO.puts(\"test\")");
        
        // Print what this looks like
        trace("Macro expression: " + haxe.macro.ExprTools.toString(expr));
        
        return expr;
    }
}