package test;

import utest.Test;
import utest.Assert;
import reflaxe.elixir.LiveViewCompiler;

using StringTools;

/**
 * Modern LiveView End-to-End Test Suite - Migrated to utest
 * 
 * Tests complete workflow from Haxe @:liveview classes to generated Elixir
 * LiveView modules, ensuring Phoenix ecosystem compatibility and production
 * performance standards. Demonstrates full compilation pipeline validation.
 * 
 * Migration patterns applied:
 * - @:asserts class → extends Test
 * - asserts.assert() → Assert.isTrue()
 * - return asserts.done() → (removed)
 * - @:describe("name") → function testName() with descriptive names
 * - Removed "Framework workaround assertion" - not needed in utest
 */
class LiveViewEndToEndTest extends Test {
    
    function testCompleteLiveViewCompilationWorkflow() {
        // Step 1: Compile mount function
        var mountCode = LiveViewCompiler.compileMountFunction(
            "params, session, socket",
            "socket = assign(socket, \"counter\", 0); {:ok, socket}"
        );
        Assert.isTrue(mountCode.contains("def mount"), "Mount function should compile successfully");
        
        // Step 2: Compile event handlers  
        var incrementHandler = LiveViewCompiler.compileHandleEvent(
            "increment", 
            "params, socket",
            "socket = assign(socket, \"counter\", socket.assigns.counter + 1); {:noreply, socket}"
        );
        var decrementHandler = LiveViewCompiler.compileHandleEvent(
            "decrement",
            "params, socket", 
            "socket = assign(socket, \"counter\", socket.assigns.counter - 1); {:noreply, socket}"
        );
        Assert.isTrue(incrementHandler.contains("def handle_event"), "Increment handler should compile");
        Assert.isTrue(decrementHandler.contains("def handle_event"), "Decrement handler should compile");
        
        // Step 3: Generate complete module
        var completeModule = LiveViewCompiler.compileToLiveView(
            "CounterLiveView",
            mountCode + "\n\n  " + incrementHandler + "\n\n  " + decrementHandler
        );
        
        Assert.isTrue(completeModule.contains("defmodule CounterLiveView"), "Should generate complete module");
        Assert.isTrue(completeModule.contains("use Phoenix.LiveView"), "Should use LiveView behaviour");
        Assert.isTrue(completeModule.length > 200, "Generated module should be substantial");
    }
    
    function testGeneratedElixirCodeStructureValidation() {
        var className = "UserLiveView";
        var content = "def mount(params, session, socket) do\n    {:ok, assign(socket, :users, [])}\n  end\n\n  def handle_event(\"create_user\", params, socket) do\n    # User creation logic here\n    {:noreply, socket}\n  end";
        
        var module = LiveViewCompiler.compileToLiveView(className, content);
        
        // Validate Elixir syntax compliance
        var validationChecks = [
            {name: "Module declaration", pattern: "defmodule UserLiveView do"},
            {name: "Phoenix.LiveView usage", pattern: "use Phoenix.LiveView"},
            {name: "Helper imports", pattern: "import Phoenix.LiveView.Helpers"},
            {name: "Socket alias", pattern: "alias Phoenix.LiveView.Socket"},
            {name: "Mount function", pattern: "def mount(params, session, socket) do"},
            {name: "Event handler", pattern: "def handle_event(\"create_user\""},
            {name: "Module closure", pattern: "end"}
        ];
        
        for (check in validationChecks) {
            Assert.isTrue(module.contains(check.pattern), '${check.name}: Should contain "${check.pattern}"');
        }
    }
    
    function testPhoenixEcosystemIntegrationCompatibility() {
        // Test that generated code follows Phoenix conventions
        var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate("TestLiveView");
        
        var phoenixChecks = [
            {name: "LiveView behaviour", check: boilerplate.contains("use Phoenix.LiveView")},
            {name: "Helper imports", check: boilerplate.contains("import Phoenix.LiveView.Helpers")},
            {name: "Form helpers", check: boilerplate.contains("import Phoenix.HTML.Form")},
            {name: "Socket alias", check: boilerplate.contains("alias Phoenix.LiveView.Socket")},
            {name: "Module naming", check: boilerplate.contains("defmodule TestLiveView")}
        ];
        
        for (check in phoenixChecks) {
            Assert.isTrue(check.check, '${check.name}: Should be Phoenix compatible');
        }
        
        // Test assign compilation produces valid Elixir
        var assignTest = LiveViewCompiler.compileAssign("socket", "current_user", "get_current_user()");
        Assert.isTrue(assignTest.contains("assign(socket, :current_user, get_current_user())"), "Assign compilation should be Phoenix compatible");
    }
    
    function testLiveViewCompilationPerformanceBenchmarking() {
        var startTime = Sys.time();
        
        // Simulate compilation of a medium-complexity LiveView
        for (i in 0...100) {
            var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate("PerfTest" + i);
            var mount = LiveViewCompiler.compileMountFunction("params, session, socket", "{:ok, socket}");
            var event = LiveViewCompiler.compileHandleEvent("test_event", "params, socket", "{:noreply, socket}");
            var assign = LiveViewCompiler.compileAssign("socket", "data", "[]");
            var module = LiveViewCompiler.compileToLiveView("PerfTest" + i, mount + "\n" + event);
        }
        
        var endTime = Sys.time();
        var duration = (endTime - startTime) * 1000; // Convert to milliseconds
        var avgDuration = duration / 100;
        
        Assert.isTrue(duration > 0, "Should take measurable time for 100 compilations");
        Assert.isTrue(avgDuration < 15, 'Average compilation should be <15ms per module, was: ${Math.round(avgDuration)}ms');
        
        // NOTE: Removed "Framework workaround assertion" - not needed in utest
        // utest doesn't have the stream corruption issue that tink_testrunner had
    }
}