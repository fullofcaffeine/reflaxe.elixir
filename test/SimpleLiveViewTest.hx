package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.LiveViewCompiler;

using StringTools;

/**
 * Simplified LiveView test that avoids Haxe API compatibility issues
 * Tests the core LiveView compilation functionality
 */
class SimpleLiveViewTest {
    public static function main() {
        trace("Running Simplified LiveView Tests...");
        
        testLiveViewDetection();
        testSocketTypes();
        testMountCompilation();
        testEventHandling();
        testAssigns();
        testBoilerplate();
        testCompleteModule();
        
        trace("✅ All simplified LiveView tests passed!");
    }
    
    static function testLiveViewDetection() {
        trace("TEST: LiveView class detection");
        
        assertTrue(LiveViewCompiler.isLiveViewClass("TestLiveView"), "Should detect TestLiveView");
        assertTrue(LiveViewCompiler.isLiveViewClass("UserLiveView"), "Should detect UserLiveView");
        assertFalse(LiveViewCompiler.isLiveViewClass("RegularClass"), "Should not detect regular class");
        
        trace("✅ LiveView detection test passed");
    }
    
    static function testSocketTypes() {
        trace("TEST: Socket type generation");
        
        var socketType = LiveViewCompiler.generateSocketType();
        assertTrue(socketType.contains("Phoenix.LiveView.Socket"), "Should reference Phoenix Socket");
        assertTrue(socketType.contains("assigns"), "Should include assigns");
        
        trace("✅ Socket type test passed");
    }
    
    static function testMountCompilation() {
        trace("TEST: Mount function compilation");
        
        var mountFn = LiveViewCompiler.compileMountFunction(
            "params, session, socket",
            "socket = Phoenix.LiveView.assign(socket, \"users\", []); return {ok: socket};"
        );
        
        assertTrue(mountFn.contains("def mount"), "Should generate mount function");
        assertTrue(mountFn.contains("params, session, socket"), "Should have correct parameters");
        assertTrue(mountFn.contains("{:ok, socket}"), "Should return {:ok, socket} tuple");
        
        trace("✅ Mount compilation test passed");
    }
    
    static function testEventHandling() {
        trace("TEST: Event handler compilation");
        
        var eventFn = LiveViewCompiler.compileHandleEvent(
            "increment",
            "params, socket", 
            "counter = socket.assigns.counter + 1; socket = assign(socket, \"counter\", counter); return {noreply: socket};"
        );
        
        assertTrue(eventFn.contains("def handle_event"), "Should generate handle_event");
        assertTrue(eventFn.contains("\"increment\""), "Should include event name");
        assertTrue(eventFn.contains("{:noreply, socket}"), "Should return noreply tuple");
        
        trace("✅ Event handling test passed");
    }
    
    static function testAssigns() {
        trace("TEST: Assign compilation");
        
        var assign = LiveViewCompiler.compileAssign("socket", "counter", "0");
        assertTrue(assign.contains("assign(socket"), "Should call assign function");
        assertTrue(assign.contains(":counter"), "Should use atom key");
        assertTrue(assign.contains("0"), "Should include value");
        
        trace("✅ Assign test passed");
    }
    
    static function testBoilerplate() {
        trace("TEST: Module boilerplate");
        
        var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate("TestLiveView");
        assertTrue(boilerplate.contains("defmodule TestLiveView"), "Should create module");
        assertTrue(boilerplate.contains("use Phoenix.LiveView"), "Should use LiveView");
        assertTrue(boilerplate.contains("import Phoenix.LiveView.Helpers"), "Should import helpers");
        
        trace("✅ Boilerplate test passed");
    }
    
    static function testCompleteModule() {
        trace("TEST: Complete module generation");
        
        var module = LiveViewCompiler.compileToLiveView("TestLiveView", "  def test, do: :ok");
        assertTrue(module.contains("defmodule TestLiveView"), "Should have module declaration");
        assertTrue(module.contains("use Phoenix.LiveView"), "Should use LiveView");
        assertTrue(module.contains("def test, do: :ok"), "Should include custom content");
        assertTrue(module.contains("end"), "Should close module");
        
        trace("✅ Complete module test passed");
    }
    
    static function assertTrue(condition: Bool, message: String) {
        if (!condition) {
            var error = '❌ ASSERTION FAILED: ${message}';
            trace(error);
            throw error;
        } else {
            trace('  ✓ ${message}');
        }
    }
    
    static function assertFalse(condition: Bool, message: String) {
        assertTrue(!condition, message);
    }
}

#end