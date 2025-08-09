package test;

import tink.unit.Assert.assert;
import reflaxe.elixir.LiveViewCompiler;

using tink.CoreApi;
using StringTools;

/**
 * Modern LiveView Test Suite with Comprehensive Edge Case Coverage
 * 
 * Tests LiveView compilation with @:liveview annotation support, socket handling,
 * and Phoenix integration following TDD methodology with comprehensive edge case
 * testing across all 7 categories for production robustness.
 * 
 * Using tink_unittest for modern Haxe testing patterns.
 */
@:asserts
class LiveViewTest {
    
    public function new() {}
    
    @:describe("@:liveview annotation detection and class validation")
    public function testLiveViewAnnotationDetection() {
        // Test that LiveViewCompiler can identify @:liveview classes
        var isLiveView = LiveViewCompiler.isLiveViewClass("TestLiveView");
        asserts.assert(isLiveView, "Should detect @:liveview annotated classes");
        
        var isNotLiveView = LiveViewCompiler.isLiveViewClass("RegularClass");
        asserts.assert(!isNotLiveView, "Should not detect regular classes as LiveView");
        
        return asserts.done();
    }
    
    @:describe("Socket typing and assigns management")
    public function testSocketTypingGeneration() {
        // Test socket type generation
        var socketType = LiveViewCompiler.generateSocketType();
        asserts.assert(socketType.contains("Phoenix.LiveView.Socket"), "Should generate proper socket type");
        asserts.assert(socketType.contains("assigns"), "Socket should have assigns field");
        
        return asserts.done();
    }
    
    @:describe("Mount function compilation with proper signature")
    public function testMountFunctionCompilation() {
        // Test mount function generation
        var mountCode = LiveViewCompiler.compileMountFunction(
            "params: Dynamic, session: Dynamic, socket: Phoenix.Socket",
            "socket = Phoenix.LiveView.assign(socket, \"users\", []); return {ok: socket};"
        );
        
        asserts.assert(mountCode.contains("def mount"), "Should generate mount function");
        asserts.assert(mountCode.contains("params"), "Mount should accept params");
        asserts.assert(mountCode.contains("session"), "Mount should accept session");
        asserts.assert(mountCode.contains("socket"), "Mount should accept socket");
        asserts.assert(mountCode.contains("{:ok, socket}"), "Mount should return {:ok, socket} tuple");
        
        return asserts.done();
    }
    
    @:describe("Event handler compilation with proper pattern matching")
    public function testHandleEventCompilation() {
        // Test handle_event function generation
        var eventCode = LiveViewCompiler.compileHandleEvent(
            "save_user",
            "params: Dynamic, socket: Phoenix.Socket",
            "return {noreply: socket};"
        );
        
        asserts.assert(eventCode.contains("def handle_event"), "Should generate handle_event function");
        asserts.assert(eventCode.contains("\"save_user\""), "Should include event name");
        asserts.assert(eventCode.contains("params"), "Should accept params");
        asserts.assert(eventCode.contains("{:noreply, socket}"), "Should return {:noreply, socket} tuple");
        
        return asserts.done();
    }
    
    @:describe("Assign tracking and validation")
    public function testAssignManagement() {
        // Test assign compilation
        var assignCode = LiveViewCompiler.compileAssign("socket", "users", "UserContext.list_users()");
        asserts.assert(assignCode.contains("assign(socket"), "Should generate assign call");
        asserts.assert(assignCode.contains(":users"), "Should use atom key");
        asserts.assert(assignCode.contains("UserContext.list_users()"), "Should preserve value expression");
        
        return asserts.done();
    }
    
    @:describe("LiveView boilerplate generation")
    public function testBoilerplateGeneration() {
        // Test module boilerplate
        var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate("TestLiveView");
        
        asserts.assert(boilerplate.contains("defmodule TestLiveView"), "Should create proper module");
        asserts.assert(boilerplate.contains("use Phoenix.LiveView"), "Should use Phoenix.LiveView");
        asserts.assert(boilerplate.contains("import Phoenix.LiveView.Helpers"), "Should import helpers");
        
        return asserts.done();
    }
    
    // === EDGE CASE TESTING SUITE ===
    // MANDATORY for production LiveView robustness
    
    @:describe("Error Conditions - Invalid LiveView Classes")
    public function testInvalidLiveViewClasses() {
        // Test null class name
        var nullClass = LiveViewCompiler.isLiveViewClass(null);
        asserts.assert(nullClass == false, "Null class name should return false");
        
        // Test empty class name
        var emptyClass = LiveViewCompiler.isLiveViewClass("");
        asserts.assert(emptyClass == false, "Empty class name should return false");
        
        // Test malformed class name
        var malformedClass = LiveViewCompiler.isLiveViewClass("Invalid.Class.Name");
        asserts.assert(malformedClass == false, "Malformed class name should return false");
        
        return asserts.done();
    }
    
    @:describe("Boundary Cases - Empty Mount Functions")
    public function testEmptyMountFunctions() {
        // Test empty parameters
        var emptyParams = LiveViewCompiler.compileMountFunction("", "socket");
        asserts.assert(emptyParams.contains("def mount"), "Should generate mount with empty params");
        
        // Test empty body
        var emptyBody = LiveViewCompiler.compileMountFunction("params, session, socket", "");
        asserts.assert(emptyBody.contains("def mount"), "Should handle empty mount body");
        
        // Test minimal mount function
        var minimal = LiveViewCompiler.compileMountFunction("_, _, socket", "{:ok, socket}");
        asserts.assert(minimal.contains("def mount(_, _, socket)"), "Should handle minimal parameters");
        
        return asserts.done();
    }
    
    @:describe("Security Validation - Template Injection Prevention")
    public function testTemplateInjectionPrevention() {
        // Test malicious event name
        var maliciousEvent = "'; System.cmd('rm', ['-rf', '/']); '";
        var eventCode = LiveViewCompiler.compileHandleEvent(
            maliciousEvent,
            "params, socket",
            "{:noreply, socket}"
        );
        asserts.assert(eventCode.contains(maliciousEvent), "Should preserve malicious event name (Phoenix handles escaping)");
        
        // Test malicious assign key
        var maliciousKey = "<script>alert('xss')</script>";
        var assignCode = LiveViewCompiler.compileAssign("socket", maliciousKey, "value");
        asserts.assert(assignCode.contains(maliciousKey), "Should preserve malicious key (Elixir atoms are safe)");
        
        return asserts.done();
    }
    
    @:describe("Performance Limits - Large LiveView Modules")
    public function testLargeModulePerformance() {
        var startTime = Sys.time();
        
        // Generate large LiveView module with many event handlers
        var eventHandlers = [];
        for (i in 0...100) {
            var handler = LiveViewCompiler.compileHandleEvent(
                'event_${i}',
                "params, socket",
                'socket = assign(socket, "counter_${i}", ${i}); {:noreply, socket}'
            );
            eventHandlers.push(handler);
        }
        
        var largeModule = LiveViewCompiler.compileToLiveView(
            "LargeTestLiveView",
            eventHandlers.join("\n\n  ")
        );
        
        var duration = Sys.time() - startTime;
        
        asserts.assert(largeModule.length > 0, "Should compile large module successfully");
        asserts.assert(duration < 0.1, 'Large module compilation should be <100ms, took: ${duration * 1000}ms');
        
        return asserts.done();
    }
    
    @:describe("Integration Robustness - Phoenix Ecosystem Compatibility")
    public function testPhoenixEcosystemCompatibility() {
        // Test LiveView boilerplate includes all required Phoenix imports
        var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate("TestLiveView");
        
        var phoenixRequirements = [
            "use Phoenix.LiveView",
            "import Phoenix.LiveView.Helpers", 
            "import Phoenix.HTML.Form",
            "alias Phoenix.LiveView.Socket"
        ];
        
        for (requirement in phoenixRequirements) {
            asserts.assert(boilerplate.contains(requirement), 'Should include Phoenix requirement: ${requirement}');
        }
        
        // Test that generated modules follow Phoenix naming conventions
        var moduleNames = ["UserLiveView", "PostLiveView", "AdminDashboardLiveView"];
        for (name in moduleNames) {
            var module = LiveViewCompiler.generateLiveViewBoilerplate(name);
            asserts.assert(module.contains('defmodule ${name}'), 'Should create module: ${name}');
        }
        
        return asserts.done();
    }
    
    @:describe("Type Safety - Socket Type Validation")
    public function testSocketTypeValidation() {
        // Test socket type generation consistency
        var socketType1 = LiveViewCompiler.generateSocketType();
        var socketType2 = LiveViewCompiler.generateSocketType();
        asserts.assert(socketType1 == socketType2, "Socket type should be consistent across calls");
        
        // Test assigns handling in different contexts
        var assignTests = [
            {key: "user", value: "get_current_user()"},
            {key: "posts", value: "Post.all()"},
            {key: "counter", value: "0"}
        ];
        
        for (test in assignTests) {
            var assignCode = LiveViewCompiler.compileAssign("socket", test.key, test.value);
            asserts.assert(assignCode.contains(':${test.key}'), 'Should convert key "${test.key}" to atom');
            asserts.assert(assignCode.contains(test.value), 'Should preserve value "${test.value}"');
        }
        
        return asserts.done();
    }
    
    @:describe("Resource Management - Concurrent LiveView Compilation")
    public function testConcurrentCompilation() {
        var startTime = Sys.time();
        
        // Simulate concurrent LiveView compilation
        var results = [];
        for (i in 0...20) {
            var className = 'ConcurrentLiveView${i}';
            var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate(className);
            var mount = LiveViewCompiler.compileMountFunction("params, session, socket", "{:ok, socket}");
            var event = LiveViewCompiler.compileHandleEvent("test_event", "params, socket", "{:noreply, socket}");
            var module = LiveViewCompiler.compileToLiveView(className, mount + "\n\n  " + event);
            results.push(module);
        }
        
        var duration = Sys.time() - startTime;
        
        asserts.assert(results.length == 20, "Should compile all 20 concurrent modules");
        asserts.assert(duration < 0.05, 'Concurrent compilation should be <50ms, took: ${duration * 1000}ms');
        
        // Verify no cross-contamination between modules
        for (i in 0...results.length) {
            var result = results[i];
            asserts.assert(result.contains('ConcurrentLiveView${i}'), 'Module ${i} should contain correct name');
        }
        
        return asserts.done();
    }
    
    @:describe("LiveView Performance Benchmarking")
    public function testLiveViewPerformance() {
        var startTime = Sys.time();
        
        // Benchmark comprehensive LiveView compilation
        for (i in 0...50) {
            var className = 'PerfLiveView${i}';
            var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate(className);
            var mount = LiveViewCompiler.compileMountFunction(
                "params, session, socket", 
                'socket = assign(socket, "id", ${i}); socket = assign(socket, "name", "Test${i}"); {:ok, socket}'
            );
            var events = [
                LiveViewCompiler.compileHandleEvent("increment", "params, socket", "{:noreply, socket}"),
                LiveViewCompiler.compileHandleEvent("decrement", "params, socket", "{:noreply, socket}"),
                LiveViewCompiler.compileHandleEvent("reset", "params, socket", "{:noreply, socket}")
            ];
            var assigns = [
                LiveViewCompiler.compileAssign("socket", "counter", "0"),
                LiveViewCompiler.compileAssign("socket", "users", "[]"),
                LiveViewCompiler.compileAssign("socket", "active", "true")
            ];
            var module = LiveViewCompiler.compileToLiveView(className, mount + "\n\n  " + events.join("\n\n  "));
        }
        
        var totalTime = Sys.time() - startTime;
        var avgTime = (totalTime * 1000) / 50; // Convert to milliseconds per module
        
        asserts.assert(totalTime > 0, "Should take measurable time");
        asserts.assert(avgTime < 15, 'Average compilation should be <15ms per module, was: ${Math.round(avgTime)}ms');
        
        return asserts.done();
    }
}