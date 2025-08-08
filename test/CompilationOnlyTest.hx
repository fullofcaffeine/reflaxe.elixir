package test;

#if (macro || reflaxe_runtime)

import elixir.WorkingExterns.Enumerable;
import elixir.WorkingExterns.ElixirMap;
import elixir.WorkingExterns.ElixirList;
import elixir.WorkingExterns.ElixirString;
import elixir.WorkingExterns.ElixirProcess;
import elixir.WorkingExterns.GenServer;
import elixir.WorkingExterns.ElixirAtom;

/**
 * Compilation-only test for working Elixir extern definitions
 * Tests that all extern modules compile without runtime errors
 */
class CompilationOnlyTest {
    public static function main() {
        trace("Running Compilation-Only Extern Tests...");
        
        // Just test that we can access the class types - no function calls
        var enumClass: Class<Dynamic> = Enumerable;
        var mapClass: Class<Dynamic> = ElixirMap;
        var listClass: Class<Dynamic> = ElixirList;
        var stringClass: Class<Dynamic> = ElixirString;
        var processClass: Class<Dynamic> = ElixirProcess;
        var genServerClass: Class<Dynamic> = GenServer;
        
        // Test that ElixirAtom enum values exist
        var okAtom = ElixirAtom.OK;
        var replyAtom = ElixirAtom.REPLY;
        var noreplyAtom = ElixirAtom.NOREPLY;
        var stopAtom = ElixirAtom.STOP;
        var continueAtom = ElixirAtom.CONTINUE;
        var hibernateAtom = ElixirAtom.HIBERNATE;
        
        // Test GenServer constants
        var genOk = GenServer.OK;
        var genReply = GenServer.REPLY;
        var genNoreply = GenServer.NOREPLY;
        var genStop = GenServer.STOP;
        var genContinue = GenServer.CONTINUE;
        var genHibernate = GenServer.HIBERNATE;
        
        // Test that helper function types exist (but don't call them)
        var replyHelper = GenServer.replyTuple;
        var noreplyHelper = GenServer.noreplyTuple;
        var stopHelper = GenServer.stopTuple;
        var continueHelper = GenServer.continueTuple;
        var hibernateHelper = GenServer.hibernateTuple;
        
        trace("✅ All Extern compilation tests passed!");
        trace("- All extern classes compile successfully");
        trace("- ElixirAtom enum values are accessible");
        trace("- GenServer constants are accessible");
        trace("- Helper function types are accessible");
    }
}

#end