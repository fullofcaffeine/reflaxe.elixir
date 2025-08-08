package test;

#if (macro || reflaxe_runtime)

import elixir.Enum as ElixirEnum;
import elixir.ElixirMap;
import elixir.List as ElixirList;
import elixir.String as ElixirString;
import elixir.Process as ElixirProcess;
import elixir.GenServer;

/**
 * Simple compilation test for Elixir extern definitions
 * Verifies that all extern functions compile and have proper signatures
 */
class SimpleExternTest {
    public static function main() {
        trace("Running Simple Extern Compilation Tests...");
        
        testExternCompilation();
        
        trace("✅ All Simple Extern tests passed!");
    }
    
    /**
     * Test that all extern function signatures compile correctly
     */
    static function testExternCompilation() {
        trace("TEST: Extern compilation");
        
        // Test Enum functions compile
        var numbers = [1, 2, 3];
        assertTrue(ElixirEnum.map != null, "ElixirEnum.map should be defined");
        assertTrue(ElixirEnum.filter != null, "ElixirEnum.filter should be defined");
        assertTrue(ElixirEnum.reduce != null, "ElixirEnum.reduce should be defined");
        
        // Test Map functions compile
        assertTrue(ElixirMap.new_ != null, "ElixirMap.new_ should be defined");
        assertTrue(ElixirMap.put != null, "ElixirMap.put should be defined");
        assertTrue(ElixirMap.get != null, "ElixirMap.get should be defined");
        
        // Test List functions compile
        assertTrue(ElixirList.first != null, "ElixirList.first should be defined");
        assertTrue(ElixirList.last != null, "ElixirList.last should be defined");
        assertTrue(ElixirList.flatten != null, "ElixirList.flatten should be defined");
        
        // Test String functions compile
        assertTrue(ElixirString.length != null, "ElixirString.length should be defined");
        assertTrue(ElixirString.trim != null, "ElixirString.trim should be defined");
        assertTrue(ElixirString.split != null, "ElixirString.split should be defined");
        
        // Test Process functions compile
        assertTrue(ElixirProcess.self != null, "ElixirProcess.self should be defined");
        assertTrue(ElixirProcess.spawn != null, "ElixirProcess.spawn should be defined");
        assertTrue(ElixirProcess.send != null, "ElixirProcess.send should be defined");
        
        // Test GenServer functions compile
        assertTrue(GenServer.start != null, "GenServer.start should be defined");
        assertTrue(GenServer.call != null, "GenServer.call should be defined");
        assertTrue(GenServer.sendCast != null, "GenServer.sendCast should be defined");
        
        // Test GenServer helper functions
        assertTrue(GenServer.replyTuple != null, "GenServer.replyTuple should be defined");
        assertTrue(GenServer.noreplyTuple != null, "GenServer.noreplyTuple should be defined");
        
        trace("✅ Extern compilation test passed");
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