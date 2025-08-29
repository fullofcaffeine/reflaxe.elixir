import reflaxe.elixir.ast.ElixirAST;

class TestElixirAST {
    static function main() {
        #if macro
        // Test that we can create AST nodes
        var atom = makeAST(EAtom("test"));
        var list = makeAST(EList([atom]));
        var module = makeAST(EModule("TestModule", [], [list]));
        
        // Test pattern creation
        var pattern = PVar("x");
        var clause: ECaseClause = {
            pattern: pattern,
            body: atom
        };
        
        // Test metadata
        var meta: ElixirMetadata = {
            requiresReturn: true,
            phoenixContext: PhoenixContext.LiveView
        };
        
        var nodeWithMeta = makeASTWithMeta(EInteger(42), meta);
        
        trace("ElixirAST compiles successfully!");
        #end
    }
}