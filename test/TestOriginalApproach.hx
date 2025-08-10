package test;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ElixirCompiler;
#end

class TestOriginalApproach {
    static function main() {
        #if (macro || reflaxe_runtime)
        // This would compile...
        var compiler = new ElixirCompiler();
        
        // But THIS would fail at runtime!
        // TSwitch doesn't exist at runtime - it's a macro-only type
        var switchExpr = {
            expr: TSwitch(null, [], null)  // ERROR: TSwitch not found
        };
        
        // Even with reflaxe_runtime, we can't create macro AST at runtime
        var result = compiler.compileExpression(switchExpr);
        #else
        trace("Can't test without reflaxe_runtime");
        #end
    }
}