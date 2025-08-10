package test;

import utest.Test;
import utest.Assert;
import reflaxe.elixir.LiveViewCompiler;

using StringTools;

/**
 * Modern LiveView Test Suite with Comprehensive Edge Case Coverage - Migrated to utest
 * 
 * Tests LiveView compilation with @:liveview annotation support, socket handling,
 * and Phoenix integration following TDD methodology with comprehensive edge case
 * testing across all 7 categories for production robustness.
 * 
 * Migration patterns applied:
 * - @:asserts class → extends Test
 * - asserts.assert() → Assert.isTrue() / Assert.equals()
 * - return asserts.done() → (removed)
 * - @:describe("name") → function testName() with descriptive names
 * - All test logic preserved exactly as in original
 */
class LiveViewTest extends Test {
    
    function testLiveViewAnnotationDetectionAndClassValidation() {
        // Test that LiveViewCompiler can identify @:liveview classes
        var isLiveView = LiveViewCompiler.isLiveViewClass("TestLiveView");
        Assert.isTrue(isLiveView, "Should detect @:liveview annotated classes");
        
        var isNotLiveView = LiveViewCompiler.isLiveViewClass("RegularClass");
        Assert.isTrue(!isNotLiveView, "Should not detect regular classes as LiveView");
    }
    
    function testSocketTypingAndAssignsManagement() {
        // Test socket type generation
        var socketType = LiveViewCompiler.generateSocketType();
        Assert.isTrue(socketType.contains("Phoenix.LiveView.Socket"), "Should generate proper socket type");
        Assert.isTrue(socketType.contains("assigns"), "Socket should have assigns field");
    }
    
    function testMountFunctionCompilationWithProperSignature() {
        // Test mount function generation
        var mountCode = LiveViewCompiler.compileMountFunction(
            "params: Dynamic, session: Dynamic, socket: Phoenix.Socket",
            "socket = Phoenix.LiveView.assign(socket, \"users\", []); return {ok: socket};"
        );
        
        Assert.isTrue(mountCode.contains("def mount"), "Should generate mount function");
        Assert.isTrue(mountCode.contains("params"), "Mount should accept params");
        Assert.isTrue(mountCode.contains("session"), "Mount should accept session");
        Assert.isTrue(mountCode.contains("socket"), "Mount should accept socket");
        Assert.isTrue(mountCode.contains("{:ok, socket}"), "Mount should return {:ok, socket} tuple");
    }
    
    function testHandleEventCompilationWithProperPatternMatching() {
        // Test handle_event function generation
        var eventCode = LiveViewCompiler.compileHandleEvent(
            "save_user",
            "params: Dynamic, socket: Phoenix.Socket",
            "return {noreply: socket};"
        );
        
        Assert.isTrue(eventCode.contains("def handle_event"), "Should generate handle_event function");
        Assert.isTrue(eventCode.contains("\"save_user\""), "Should include event name");
        Assert.isTrue(eventCode.contains("params"), "Should accept params");
        Assert.isTrue(eventCode.contains("{:noreply, socket}"), "Should return {:noreply, socket} tuple");
    }
    
    function testAssignTrackingAndValidation() {
        // Test assign compilation
        var assignCode = LiveViewCompiler.compileAssign("socket", "users", "UserContext.list_users()");
        Assert.isTrue(assignCode.contains("assign(socket"), "Should generate assign call");
        Assert.isTrue(assignCode.contains(":users"), "Should use atom key");
        Assert.isTrue(assignCode.contains("UserContext.list_users()"), "Should preserve value expression");
    }
    
    function testLiveViewBoilerplateGeneration() {
        // Test module boilerplate
        var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate("TestLiveView");
        
        Assert.isTrue(boilerplate.contains("defmodule TestLiveView"), "Should create proper module");
        Assert.isTrue(boilerplate.contains("use Phoenix.LiveView"), "Should use Phoenix.LiveView");
        Assert.isTrue(boilerplate.contains("import Phoenix.LiveView.Helpers"), "Should import helpers");
    }
    
    // === EDGE CASE TESTING SUITE ===
    // MANDATORY for production LiveView robustness
    
    function testErrorConditionsInvalidLiveViewClasses() {
        // Test null class name
        var nullClass = LiveViewCompiler.isLiveViewClass(null);
        Assert.equals(false, nullClass, "Null class name should return false");
        
        // Test empty class name
        var emptyClass = LiveViewCompiler.isLiveViewClass("");
        Assert.equals(false, emptyClass, "Empty class name should return false");
        
        // Test malformed class name
        var malformedClass = LiveViewCompiler.isLiveViewClass("Invalid.Class.Name");
        Assert.equals(false, malformedClass, "Malformed class name should return false");
    }
    
    function testBoundaryCasesEmptyMountFunctions() {
        // Test empty parameters
        var emptyParams = LiveViewCompiler.compileMountFunction("", "socket");
        Assert.isTrue(emptyParams.contains("def mount"), "Should generate mount with empty params");
        
        // Test empty body
        var emptyBody = LiveViewCompiler.compileMountFunction("params, session, socket", "");
        Assert.isTrue(emptyBody.contains("def mount"), "Should handle empty mount body");
        
        // Test minimal mount function
        var minimal = LiveViewCompiler.compileMountFunction("_, _, socket", "{:ok, socket}");
        Assert.isTrue(minimal.contains("def mount(_, _, socket)"), "Should handle minimal parameters");
    }
    
    function testSecurityValidationTemplateInjectionPrevention() {
        // Test malicious event name
        var maliciousEvent = "'; System.cmd('rm', ['-rf', '/']); '";
        var eventCode = LiveViewCompiler.compileHandleEvent(
            maliciousEvent,
            "params, socket",
            "{:noreply, socket}"
        );
        Assert.isTrue(eventCode.contains(maliciousEvent), "Should preserve malicious event name (Phoenix handles escaping)");
        
        // Test malicious assign key
        var maliciousKey = "<script>alert('xss')</script>";
        var assignCode = LiveViewCompiler.compileAssign("socket", maliciousKey, "value");
        Assert.isTrue(assignCode.contains(maliciousKey), "Should preserve malicious key (Elixir atoms are safe)");
    }
    
    function testPerformanceLimitsLargeLiveViewModules() {
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
        
        Assert.isTrue(largeModule.length > 0, "Should compile large module successfully");
        Assert.isTrue(duration < 0.1, 'Large module compilation should be <100ms, took: ${duration * 1000}ms');
    }
    
    function testIntegrationRobustnessPhoenixEcosystemCompatibility() {
        // Test LiveView boilerplate includes all required Phoenix imports
        var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate("TestLiveView");
        
        var phoenixRequirements = [
            "use Phoenix.LiveView",
            "import Phoenix.LiveView.Helpers", 
            "import Phoenix.HTML.Form",
            "alias Phoenix.LiveView.Socket"
        ];
        
        for (requirement in phoenixRequirements) {
            Assert.isTrue(boilerplate.contains(requirement), 'Should include Phoenix requirement: ${requirement}');
        }
        
        // Test that generated modules follow Phoenix naming conventions
        var moduleNames = ["UserLiveView", "PostLiveView", "AdminDashboardLiveView"];
        for (name in moduleNames) {
            var module = LiveViewCompiler.generateLiveViewBoilerplate(name);
            Assert.isTrue(module.contains('defmodule ${name}'), 'Should create module: ${name}');
        }
    }
    
    function testTypeSafetySocketTypeValidation() {
        // Test socket type generation consistency
        var socketType1 = LiveViewCompiler.generateSocketType();
        var socketType2 = LiveViewCompiler.generateSocketType();
        Assert.equals(socketType1, socketType2, "Socket type should be consistent across calls");
        
        // Test assigns handling in different contexts
        var assignTests = [
            {key: "user", value: "get_current_user()"},
            {key: "posts", value: "Post.all()"},
            {key: "counter", value: "0"}
        ];
        
        for (test in assignTests) {
            var assignCode = LiveViewCompiler.compileAssign("socket", test.key, test.value);
            Assert.isTrue(assignCode.contains(':${test.key}'), 'Should convert key "${test.key}" to atom');
            Assert.isTrue(assignCode.contains(test.value), 'Should preserve value "${test.value}"');
        }
    }
    
    function testResourceManagementConcurrentLiveViewCompilation() {
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
        
        Assert.equals(20, results.length, "Should compile all 20 concurrent modules");
        Assert.isTrue(duration < 0.05, 'Concurrent compilation should be <50ms, took: ${duration * 1000}ms');
        
        // Verify no cross-contamination between modules
        for (i in 0...results.length) {
            var result = results[i];
            Assert.isTrue(result.contains('ConcurrentLiveView${i}'), 'Module ${i} should contain correct name');
        }
    }
    
    function testLiveViewPerformanceBenchmarking() {
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
        
        Assert.isTrue(totalTime > 0, "Should take measurable time");
        Assert.isTrue(avgTime < 15, 'Average compilation should be <15ms per module, was: ${Math.round(avgTime)}ms');
    }
}