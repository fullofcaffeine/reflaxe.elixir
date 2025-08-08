package test;

#if (macro || reflaxe_runtime)

import elixir.Enumerable;
import elixir.ElixirMap;
import elixir.List as ElixirList;
import elixir.Process as ElixirProcess;
import elixir.GenServer;
import elixir.GenServer.ElixirAtom;

/**
 * Test all extern definitions compile together and work correctly
 * This avoids String conflicts by not importing elixir.String
 */
class AllExternTest {
    public static function main() {
        trace("Running All Extern Compilation Tests...");
        
        testExternBasics();
        testGenServerWithEnum();
        
        trace("✅ All Extern tests passed!");
    }
    
    static function testExternBasics() {
        trace("TEST: Basic extern compilation");
        
        // Test all extern functions are defined
        assertTrue(Enumerable.map != null, "Enumerable.map should be defined");
        assertTrue(ElixirMap.new_ != null, "ElixirMap.new_ should be defined");
        assertTrue(ElixirList.first != null, "ElixirList.first should be defined");
        assertTrue(ElixirProcess.self != null, "ElixirProcess.self should be defined");
        assertTrue(GenServer.start != null, "GenServer.start should be defined");
        
        trace("✅ Basic extern compilation test passed");
    }
    
    static function testGenServerWithEnum() {
        trace("TEST: GenServer with ElixirAtom enum");
        
        // Test that ElixirAtom enum constants work properly
        assertTrue(GenServer.OK == ElixirAtom.OK, "GenServer.OK should equal ElixirAtom.OK");
        assertTrue(GenServer.REPLY == ElixirAtom.REPLY, "GenServer.REPLY should equal ElixirAtom.REPLY");
        assertTrue(GenServer.NOREPLY == ElixirAtom.NOREPLY, "GenServer.NOREPLY should equal ElixirAtom.NOREPLY");
        
        // Test helper functions return proper types
        var replyTuple = GenServer.replyTuple("response", "state");
        assertTrue(replyTuple._0 == ElixirAtom.REPLY, "Reply tuple should have REPLY atom");
        
        var noreplyTuple = GenServer.noreplyTuple("state");
        assertTrue(noreplyTuple._0 == ElixirAtom.NOREPLY, "Noreply tuple should have NOREPLY atom");
        
        var stopTuple = GenServer.stopTuple("normal", "state");
        assertTrue(stopTuple._0 == ElixirAtom.STOP, "Stop tuple should have STOP atom");
        
        trace("✅ GenServer with ElixirAtom enum test passed");
    }
    
    // Test helper function
    static function assertTrue(condition: Bool, message: String) {
        if (!condition) {
            var error = '❌ ASSERTION FAILED: ${message}';
            trace(error);
            throw error;
        } else {
            trace('  ✓ ${message}');
        }
    }
}

#end