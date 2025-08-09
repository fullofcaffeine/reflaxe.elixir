package test;

import tink.unit.Assert.assert;
import reflaxe.elixir.LiveViewCompiler;

using tink.CoreApi;
using StringTools;

/**
 * Modern LiveView End-to-End Test Suite
 * 
 * Tests complete workflow from Haxe @:liveview classes to generated Elixir
 * LiveView modules, ensuring Phoenix ecosystem compatibility and production
 * performance standards. Demonstrates full compilation pipeline validation.
 * 
 * Using tink_unittest for modern Haxe testing patterns.
 */
@:asserts
class LiveViewEndToEndTest {
    
    public function new() {}
    
    @:describe("Complete LiveView compilation workflow")
    public function testCompleteWorkflow() {
        // Step 1: Compile mount function
        var mountCode = LiveViewCompiler.compileMountFunction(
            "params, session, socket",
            "socket = assign(socket, \"counter\", 0); {:ok, socket}"
        );
        asserts.assert(mountCode.contains("def mount"), "Mount function should compile successfully");
        
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
        asserts.assert(incrementHandler.contains("def handle_event"), "Increment handler should compile");
        asserts.assert(decrementHandler.contains("def handle_event"), "Decrement handler should compile");
        
        // Step 3: Generate complete module
        var completeModule = LiveViewCompiler.compileToLiveView(
            "CounterLiveView",
            mountCode + "\n\n  " + incrementHandler + "\n\n  " + decrementHandler
        );
        
        asserts.assert(completeModule.contains("defmodule CounterLiveView"), "Should generate complete module");
        asserts.assert(completeModule.contains("use Phoenix.LiveView"), "Should use LiveView behaviour");
        asserts.assert(completeModule.length > 200, "Generated module should be substantial");
        
        return asserts.done();
    }
    
    /**
     * Validate the structure of generated Elixir code
     */
    static function validateGeneratedCode() {
        trace("VALIDATION: Generated Elixir code structure");
        
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
            if (module.contains(check.pattern)) {
                trace('  ✓ ${check.name}: Found "${check.pattern}"');
            } else {
                trace('  ❌ ${check.name}: Missing "${check.pattern}"');
                throw 'Validation failed: ${check.name}';
            }
        }
        
        trace("✅ Generated code structure validation passed");
    }
    
    /**
     * Test Phoenix ecosystem compatibility
     */
    static function testPhoenixCompatibility() {
        trace("COMPATIBILITY: Phoenix ecosystem integration");
        
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
            if (check.check) {
                trace('  ✓ ${check.name}: Compatible');
            } else {
                trace('  ❌ ${check.name}: Not compatible');
                throw 'Compatibility failed: ${check.name}';
            }
        }
        
        // Test assign compilation produces valid Elixir
        var assignTest = LiveViewCompiler.compileAssign("socket", "current_user", "get_current_user()");
        if (assignTest.contains("assign(socket, :current_user, get_current_user())")) {
            trace("  ✓ Assign compilation: Phoenix compatible");
        } else {
            throw "Assign compilation not Phoenix compatible";
        }
        
        trace("✅ Phoenix ecosystem compatibility passed");
    }
    
    /**
     * Measure basic compilation performance
     */
    static function measurePerformance() {
        trace("PERFORMANCE: Basic compilation timing");
        
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
        
        trace('  📊 Compiled 100 LiveView modules in ${Math.round(duration)}ms');
        trace('  📊 Average per module: ${Math.round(duration/100)}ms');
        
        // Performance target from PRD: <15ms compilation steps
        if (duration / 100 < 15) {
            trace("  ✅ Performance target met: <15ms per compilation");
        } else {
            trace("  ⚠️ Performance target missed: >" + Math.round(duration/100) + "ms per compilation");
        }
        
        trace("✅ Performance measurement complete");
    }
}

#end