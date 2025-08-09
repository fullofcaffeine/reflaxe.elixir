package test;

#if (macro || reflaxe_runtime)

/**
 * Simple test to verify ChangesetCompiler compilation
 */
class SimpleChangesetTest {
    public static function main(): Void {
        trace("Testing ChangesetCompiler compilation...");
        
        try {
            // Test basic functionality
            var result = reflaxe.elixir.helpers.ChangesetCompiler.isChangesetClass("UserChangeset");
            trace("✅ ChangesetCompiler.isChangesetClass works: " + result);
            
            var validation = reflaxe.elixir.helpers.ChangesetCompiler.compileValidation("email", "required");  
            trace("✅ ChangesetCompiler.compileValidation works: " + validation);
            
            var module = reflaxe.elixir.helpers.ChangesetCompiler.generateChangesetModule("TestChangeset");
            trace("✅ ChangesetCompiler.generateChangesetModule works - length: " + module.length);
            
            trace("🟢 All basic tests passed - ChangesetCompiler GREEN phase working!");
        } catch (e: Dynamic) {
            trace("🔴 Error: " + e);
        }
    }
}

#end