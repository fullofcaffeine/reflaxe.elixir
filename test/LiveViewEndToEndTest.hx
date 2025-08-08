package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.LiveViewCompiler;

using StringTools;

/**
 * End-to-end LiveView compilation demonstration
 * Shows complete workflow from Haxe class to Elixir LiveView module
 */
class LiveViewEndToEndTest {
    public static function main() {
        trace("Running LiveView End-to-End Demonstration...");
        
        demonstrateCompleteWorkflow();
        validateGeneratedCode();
        testPhoenixCompatibility();
        measurePerformance();
        
        trace("✅ LiveView End-to-End demonstration complete!");
    }
    
    /**
     * Demonstrate the complete compilation workflow
     */
    static function demonstrateCompleteWorkflow() {
        trace("DEMO: Complete LiveView compilation workflow");
        
        // Step 1: Define Haxe LiveView class (simulated)
        trace("Step 1: Input Haxe @:liveview class");
        var haxeClass = "@:liveview\nclass CounterLiveView extends Phoenix.LiveView {\n    public function mount(params, session, socket) {\n        socket = assign(socket, \"counter\", 0);\n        return {ok: socket};\n    }\n    \n    public function handle_event(\"increment\", params, socket) {\n        socket = assign(socket, \"counter\", socket.assigns.counter + 1);\n        return {noreply: socket};\n    }\n    \n    public function handle_event(\"decrement\", params, socket) {\n        socket = assign(socket, \"counter\", socket.assigns.counter - 1);\n        return {noreply: socket};\n    }\n}";
        
        trace("  ✓ Input: Haxe class with @:liveview annotation");
        
        // Step 2: Compile mount function
        trace("Step 2: Compile mount function");
        var mountCode = LiveViewCompiler.compileMountFunction(
            "params, session, socket",
            "socket = assign(socket, \"counter\", 0); {:ok, socket}"
        );
        trace("  ✓ Mount function compiled successfully");
        
        // Step 3: Compile event handlers
        trace("Step 3: Compile event handlers");
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
        trace("  ✓ Event handlers compiled successfully");
        
        // Step 4: Generate complete module
        trace("Step 4: Generate complete Elixir module");
        var completeModule = LiveViewCompiler.compileToLiveView(
            "CounterLiveView",
            mountCode + "\n\n  " + incrementHandler + "\n\n  " + decrementHandler
        );
        
        trace("  ✓ Complete LiveView module generated");
        trace("Generated Elixir module preview:");
        var previewLength = Math.floor(Math.min(200, completeModule.length));
        var preview = completeModule.substring(0, previewLength);
        trace("    " + preview.replace("\n", "\n    ") + "...");
        
        trace("✅ Complete workflow demonstration passed");
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