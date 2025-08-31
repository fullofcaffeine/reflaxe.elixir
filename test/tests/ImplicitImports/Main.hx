/**
 * Test for implicit import detection in Reflaxe.Elixir
 * 
 * This test verifies that the AST transformation passes correctly detect
 * usage patterns and automatically add necessary imports:
 * 1. Bitwise operators trigger `import Bitwise`
 * 2. HXX templates trigger `use Phoenix.Component`
 * 3. LiveView components trigger `import AppWeb.CoreComponents`
 */

import reflaxe.elixir.HXX;

// Test 1: Bitwise operations should trigger Bitwise import
class BitwiseOperations {
    public static function testBitwise(): Int {
        var a = 0xFF;
        var b = 0x0F;
        
        // Test all bitwise operators (Haxe syntax -> Elixir triple operators)
        var andResult = a & b;        // Bitwise AND -> &&&
        var orResult = a | b;         // Bitwise OR -> |||
        var xorResult = a ^ b;        // Bitwise XOR -> ^^^
        var notResult = ~a;           // Bitwise NOT -> ~~~
        var leftShift = a << 2;       // Left shift -> <<<
        var rightShift = a >>> 2;     // Right shift -> >>>
        
        return andResult + orResult + xorResult + notResult + leftShift + rightShift;
    }
    
    // Nested usage in complex expression
    public static function complexBitwise(): Int {
        var mask = 0xFF;
        var value = 0x12345678;
        
        // Complex expression with multiple bitwise ops
        return (value & mask) | ((value >>> 8) & mask);
    }
}

// Test 2: HXX templates should trigger Phoenix.Component import
@:native("TestAppWeb.TestComponent")
class TestComponent {
    public static function render(assigns: Dynamic): String {
        // This should generate ~H sigil and trigger use Phoenix.Component
        return HXX.hxx('
            <div class={@className}>
                <h1><%= @title %></h1>
                <p><%= @content %></p>
            </div>
        ');
    }
    
    public static function button(assigns: Dynamic): String {
        return HXX.hxx('
            <button type={@type || "button"} disabled={@disabled}>
                <%= @label %>
            </button>
        ');
    }
}

// Test 3: LiveView with components should trigger CoreComponents import
@:native("TestAppWeb.TestLive")
@:liveview
class TestLive {
    public static function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic {
        return {
            status: "ok",
            socket: socket
        };
    }
    
    public static function render(assigns: Dynamic): String {
        // Component usage should trigger CoreComponents import
        return HXX.hxx('
            <div>
                <.header title="Test Page" />
                
                <.button type="submit">
                    Submit Form
                </.button>
                
                <.input field={@form["name"]} label="Name" />
                
                <.modal id="test-modal" show={@show_modal}>
                    Modal Content Here
                </.modal>
            </div>
        ');
    }
    
    public static function handle_event(event: String, params: Dynamic, socket: Dynamic): Dynamic {
        return {
            status: "noreply",
            socket: socket
        };
    }
}

// Main entry point
class Main {
    static function main() {
        // Call the test functions to ensure they compile
        BitwiseOperations.testBitwise();
        BitwiseOperations.complexBitwise();
        
        var assigns = {
            className: "container",
            title: "Test Title",
            content: "Test content",
            type: "button",
            disabled: false,
            label: "Click me"
        };
        
        TestComponent.render(assigns);
        TestComponent.button(assigns);
        
        trace("Implicit imports test compiled successfully");
    }
}