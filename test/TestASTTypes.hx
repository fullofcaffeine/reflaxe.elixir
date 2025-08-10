package test;

class TestASTTypes {
    static function main() {
        // Try to use macro-time AST types at runtime
        // This will fail even with reflaxe_runtime!
        
        #if macro
        // This would work at macro-time
        var expr = haxe.macro.TypedExprDef.TConst(TString("test"));
        trace("At macro time, AST types exist");
        #else
        // But at runtime, even with reflaxe_runtime...
        #if reflaxe_runtime
        trace("reflaxe_runtime is defined, but...");
        // This won't compile - TConst doesn't exist at runtime!
        // var expr = TConst(TString("test"));  // ERROR!
        trace("We still can't create AST types at runtime");
        #else
        trace("Not in reflaxe_runtime mode");
        #end
        #end
    }
}