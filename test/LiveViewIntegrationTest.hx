package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.LiveViewCompiler;
import reflaxe.elixir.ElixirCompiler;

using StringTools;

/**
 * Integration tests for LiveView compilation with ElixirCompiler
 * Tests the complete compilation pipeline for @:liveview classes
 */
class LiveViewIntegrationTest {
    public static function main() {
        trace("Running LiveView Integration Tests...");
        
        testLiveViewModuleGeneration();
        testEventHandlerCompilation();
        testSocketAssignCompilation();
        testPhoenixIntegration();
        
        trace("✅ All LiveView integration tests passed!");
    }
    
    /**
     * Test complete LiveView module generation
     */
    static function testLiveViewModuleGeneration() {
        trace("TEST: Complete LiveView module generation");
        
        var className = "TestLiveView";
        var classContent = "def mount(params, session, socket) do\n    socket\n    |> assign(:counter, 0)\n    |> assign(:message, \"Hello LiveView!\")\n    \n    {:ok, socket}\n  end\n  \n  def handle_event(\"increment\", _params, socket) do\n    counter = socket.assigns.counter\n    socket = assign(socket, :counter, counter + 1)\n    {:noreply, socket}\n  end";
        
        var result = LiveViewCompiler.compileToLiveView(className, classContent);
        
        // Verify module structure
        assertTrue(result.contains("defmodule TestLiveView"), "Should create proper module");
        assertTrue(result.contains("use Phoenix.LiveView"), "Should use Phoenix.LiveView");
        assertTrue(result.contains("import Phoenix.LiveView.Helpers"), "Should import helpers");
        assertTrue(result.contains("alias Phoenix.LiveView.Socket"), "Should alias Socket");
        assertTrue(result.contains("def mount"), "Should include mount function");
        assertTrue(result.contains("def handle_event"), "Should include event handlers");
        
        trace("✅ Complete LiveView module generation test passed");
    }
    
    /**
     * Test event handler compilation patterns
     */
    static function testEventHandlerCompilation() {
        trace("TEST: Event handler compilation patterns");
        
        // Test multiple event patterns
        var events = [
            {name: "increment", body: "socket = assign(socket, :counter, socket.assigns.counter + 1); {:noreply, socket}"},
            {name: "save_form", body: "case validate_form(params) do; {:ok, data} -> {:noreply, assign(socket, :data, data)}; {:error, errors} -> {:noreply, assign(socket, :errors, errors)}; end"},
            {name: "delete_item", body: "MyApp.delete_item(params.id); {:noreply, socket}"}
        ];
        
        for (event in events) {
            var result = LiveViewCompiler.compileHandleEvent(event.name, "params, socket", event.body);
            
            assertTrue(result.contains('def handle_event("${event.name}"'), "Should handle event: " + event.name);
            assertTrue(result.contains("params, socket"), "Should accept params and socket");
            
            if (event.body.contains("{:noreply")) {
                assertTrue(result.contains("{:noreply"), "Should return proper tuple for: " + event.name);
            }
        }
        
        trace("✅ Event handler compilation test passed");
    }
    
    /**
     * Test socket assign compilation with type safety
     */
    static function testSocketAssignCompilation() {
        trace("TEST: Socket assign compilation with type safety");
        
        // Test various assign patterns
        var assigns = [
            {socket: "socket", key: "users", value: "UserContext.list_users()"},
            {socket: "socket", key: "counter", value: "0"},
            {socket: "socket", key: "form_data", value: "%{name: \"\", email: \"\"}"},
            {socket: "updated_socket", key: "timestamp", value: "DateTime.utc_now()"}
        ];
        
        for (assign in assigns) {
            var result = LiveViewCompiler.compileAssign(assign.socket, assign.key, assign.value);
            
            assertTrue(result.contains("assign(" + assign.socket), "Should call assign function");
            assertTrue(result.contains(":" + assign.key), "Should use atom key: " + assign.key);
            assertTrue(result.contains(assign.value), "Should preserve value: " + assign.value);
        }
        
        trace("✅ Socket assign compilation test passed");
    }
    
    /**
     * Test Phoenix ecosystem integration points
     */
    static function testPhoenixIntegration() {
        trace("TEST: Phoenix ecosystem integration");
        
        // Test that LiveView compiler works with PhoenixMapper patterns
        var boilerplate = LiveViewCompiler.generateLiveViewBoilerplate("UserLiveView");
        
        // Verify Phoenix ecosystem imports and usage
        assertTrue(boilerplate.contains("use Phoenix.LiveView"), "Should use Phoenix.LiveView");
        assertTrue(boilerplate.contains("import Phoenix.LiveView.Helpers"), "Should import LiveView helpers");
        assertTrue(boilerplate.contains("import Phoenix.HTML.Form"), "Should import form helpers");
        assertTrue(boilerplate.contains("alias Phoenix.LiveView.Socket"), "Should alias Socket type");
        
        // Test module naming follows Phoenix conventions
        assertTrue(boilerplate.contains("defmodule UserLiveView"), "Should follow Phoenix module naming");
        
        trace("✅ Phoenix ecosystem integration test passed");
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