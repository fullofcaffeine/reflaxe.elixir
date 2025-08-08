package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.LiveViewCompiler;
using StringTools;

/**
 * Test LiveView compilation and @:liveview annotation support
 * Tests following BDD approach - testing the interface consumers will use
 */
class LiveViewTest {
    public static function main() {
        trace("Running LiveView Compiler Tests...");
        
        testLiveViewAnnotationDetection();
        testSocketTypingGeneration();
        testMountFunctionCompilation();
        testHandleEventCompilation();
        testAssignManagement();
        testBoilerplateGeneration();
        
        trace("✅ All LiveView tests passed!");
    }
    
    /**
     * Test @:liveview annotation detection and class validation
     */
    static function testLiveViewAnnotationDetection() {
        trace("TEST: @:liveview annotation detection");
        
        // Test that LiveViewCompiler can identify @:liveview classes
        var isLiveView = LiveViewCompiler.isLiveViewClass("TestLiveView");
        assertTrue(isLiveView, "Should detect @:liveview annotated classes");
        
        var isNotLiveView = LiveViewCompiler.isLiveViewClass("RegularClass");
        assertFalse(isNotLiveView, "Should not detect regular classes as LiveView");
        
        trace("✅ LiveView annotation detection test passed");
    }
    
    /**
     * Test proper socket typing with assigns management
     */
    static function testSocketTypingGeneration() {
        trace("TEST: Socket typing and assigns management");
        
        // Test socket type generation
        var socketType = LiveViewCompiler.generateSocketType();
        assertTrue(socketType.contains("Phoenix.LiveView.Socket"), "Should generate proper socket type");
        assertTrue(socketType.contains("assigns"), "Socket should have assigns field");
        
        trace("✅ Socket typing generation test passed");
    }
    
    /**
     * Test mount function compilation with proper signature
     */
    static function testMountFunctionCompilation() {
        trace("TEST: Mount function compilation");
        
        // Test mount function generation
        var mountCode = LiveViewCompiler.compileMountFunction(
            "params: Dynamic, session: Dynamic, socket: Phoenix.Socket",
            "socket = Phoenix.LiveView.assign(socket, \"users\", []); return {ok: socket};"
        );
        
        assertTrue(mountCode.contains("def mount"), "Should generate mount function");
        assertTrue(mountCode.contains("params"), "Mount should accept params");
        assertTrue(mountCode.contains("session"), "Mount should accept session");
        assertTrue(mountCode.contains("socket"), "Mount should accept socket");
        assertTrue(mountCode.contains("{:ok, socket}"), "Mount should return {:ok, socket} tuple");
        
        trace("✅ Mount function compilation test passed");
    }
    
    /**
     * Test event handler compilation with proper pattern matching
     */
    static function testHandleEventCompilation() {
        trace("TEST: Handle event compilation");
        
        // Test handle_event function generation
        var eventCode = LiveViewCompiler.compileHandleEvent(
            "save_user",
            "params: Dynamic, socket: Phoenix.Socket",
            "return {noreply: socket};"
        );
        
        assertTrue(eventCode.contains("def handle_event"), "Should generate handle_event function");
        assertTrue(eventCode.contains("\"save_user\""), "Should include event name");
        assertTrue(eventCode.contains("params"), "Should accept params");
        assertTrue(eventCode.contains("{:noreply, socket}"), "Should return {:noreply, socket} tuple");
        
        trace("✅ Handle event compilation test passed");
    }
    
    /**
     * Test assign tracking and validation
     */
    static function testAssignManagement() {
        trace("TEST: Assign tracking and validation");
        
        // Test assign compilation
        var assignCode = LiveViewCompiler.compileAssign("socket", "users", "UserContext.list_users()");
        assertTrue(assignCode.contains("assign(socket"), "Should generate assign call");
        assertTrue(assignCode.contains(":users"), "Should use atom key");
        assertTrue(assignCode.contains("UserContext.list_users()"), "Should preserve value expression");
        
        trace("✅ Assign management test passed");
    }
    
    /**
     * Test LiveView boilerplate generation
     */
    static function testBoilerplateGeneration() {
        trace("TEST: LiveView boilerplate generation");
        
        // Test module boilerplate
        var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate("TestLiveView");
        
        assertTrue(boilerplate.contains("defmodule TestLiveView"), "Should create proper module");
        assertTrue(boilerplate.contains("use Phoenix.LiveView"), "Should use Phoenix.LiveView");
        assertTrue(boilerplate.contains("import Phoenix.LiveView.Helpers"), "Should import helpers");
        
        trace("✅ LiveView boilerplate generation test passed");
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
    
    static function assertFalse(condition: Bool, message: String) {
        assertTrue(!condition, message);
    }
}

#end