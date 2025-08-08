package test;

#if (macro || reflaxe_runtime)

import elixir.ElixirMap;
import elixir.List as ElixirList;
import elixir.Process as ElixirProcess;
import elixir.GenServer;
import elixir.GenServer.ElixirAtom;

/**
 * Clean test avoiding Enum/String conflicts
 * Tests core extern functionality without problematic imports
 */
class CleanExternTest {
    public static function main() {
        trace("Running Clean Extern Tests...");
        
        testCoreExterns();
        testGenServerEnums();
        
        trace("✅ All Clean Extern tests passed!");
    }
    
    static function testCoreExterns() {
        trace("TEST: Core extern definitions");
        
        // Test Map functions
        assertTrue(ElixirMap.new_ != null, "ElixirMap.new_ should be defined");
        assertTrue(ElixirMap.put != null, "ElixirMap.put should be defined");
        assertTrue(ElixirMap.get != null, "ElixirMap.get should be defined");
        
        // Test List functions
        assertTrue(ElixirList.first != null, "ElixirList.first should be defined");
        assertTrue(ElixirList.last != null, "ElixirList.last should be defined");
        assertTrue(ElixirList.flatten != null, "ElixirList.flatten should be defined");
        
        // Test Process functions
        assertTrue(ElixirProcess.self != null, "ElixirProcess.self should be defined");
        assertTrue(ElixirProcess.spawn != null, "ElixirProcess.spawn should be defined");
        assertTrue(ElixirProcess.send != null, "ElixirProcess.send should be defined");
        
        // Test GenServer functions
        assertTrue(GenServer.start != null, "GenServer.start should be defined");
        assertTrue(GenServer.call != null, "GenServer.call should be defined");
        assertTrue(GenServer.sendCast != null, "GenServer.sendCast should be defined");
        
        trace("✅ Core extern definitions test passed");
    }
    
    static function testGenServerEnums() {
        trace("TEST: GenServer ElixirAtom enum functionality");
        
        // Test enum constants are properly defined
        assertTrue(GenServer.OK == ElixirAtom.OK, "GenServer.OK should equal ElixirAtom.OK");
        assertTrue(GenServer.REPLY == ElixirAtom.REPLY, "GenServer.REPLY should equal ElixirAtom.REPLY");
        assertTrue(GenServer.NOREPLY == ElixirAtom.NOREPLY, "GenServer.NOREPLY should equal ElixirAtom.NOREPLY");
        assertTrue(GenServer.STOP == ElixirAtom.STOP, "GenServer.STOP should equal ElixirAtom.STOP");
        assertTrue(GenServer.CONTINUE == ElixirAtom.CONTINUE, "GenServer.CONTINUE should equal ElixirAtom.CONTINUE");
        assertTrue(GenServer.HIBERNATE == ElixirAtom.HIBERNATE, "GenServer.HIBERNATE should equal ElixirAtom.HIBERNATE");
        
        // Test helper functions with enum types
        var replyTuple = GenServer.replyTuple("response", "state");
        assertTrue(replyTuple._0 == ElixirAtom.REPLY, "Reply tuple should use ElixirAtom.REPLY");
        assertTrue(replyTuple._1 == "response", "Reply tuple should contain response");
        assertTrue(replyTuple._2 == "state", "Reply tuple should contain state");
        
        var noreplyTuple = GenServer.noreplyTuple("new_state");
        assertTrue(noreplyTuple._0 == ElixirAtom.NOREPLY, "Noreply tuple should use ElixirAtom.NOREPLY");
        assertTrue(noreplyTuple._1 == "new_state", "Noreply tuple should contain state");
        
        var stopTuple = GenServer.stopTuple("normal", "final_state");
        assertTrue(stopTuple._0 == ElixirAtom.STOP, "Stop tuple should use ElixirAtom.STOP");
        assertTrue(stopTuple._1 == "normal", "Stop tuple should contain reason");
        assertTrue(stopTuple._2 == "final_state", "Stop tuple should contain state");
        
        var continueTuple = GenServer.continueTuple("state", "continue_data");
        assertTrue(continueTuple._0 == ElixirAtom.CONTINUE, "Continue tuple should use ElixirAtom.CONTINUE");
        assertTrue(continueTuple._1 == "state", "Continue tuple should contain state");
        assertTrue(continueTuple._2 == "continue_data", "Continue tuple should contain continue data");
        
        var hibernateTuple = GenServer.hibernateTuple("hibernating_state");
        assertTrue(hibernateTuple._0 == ElixirAtom.NOREPLY, "Hibernate tuple should use ElixirAtom.NOREPLY");
        assertTrue(hibernateTuple._1 == "hibernating_state", "Hibernate tuple should contain state");
        assertTrue(hibernateTuple._2 == ElixirAtom.HIBERNATE, "Hibernate tuple should use ElixirAtom.HIBERNATE");
        
        trace("✅ GenServer ElixirAtom enum functionality test passed");
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