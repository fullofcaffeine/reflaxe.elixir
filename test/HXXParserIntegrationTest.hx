package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.macro.HXXMacro;
import reflaxe.elixir.macro.HXXParser;

using StringTools;

/**
 * Integration test for HXXParser with HXXMacro system
 * Validates that the REFACTOR phase enhancements work correctly
 */
class HXXParserIntegrationTest {
    public static function main() {
        trace("Running HXXParser Integration Tests...");
        
        testEnhancedParsing();
        testErrorHandling();
        testEventHandlerExtraction();
        testBindingExtraction();
        
        trace("✅ All HXXParser integration tests passed!");
    }
    
    /**
     * Test enhanced parsing capabilities
     */
    static function testEnhancedParsing() {
        trace("TEST: Enhanced JSX parsing with HXXParser");
        
        var jsx = '<div className="container" onClick="handleClick">Hello World</div>';
        var element = HXXParser.parseJSXElement(jsx);
        
        assertTrue(element.valid, "Should parse JSX successfully");
        assertTrue(element.tag == "div", "Should extract tag correctly");
        assertTrue(element.content == "Hello World", "Should extract content");
        assertTrue(element.errors.length == 0, "Should have no parsing errors");
        
        // Test attribute extraction
        var className = element.attributes.get("className");
        var onClick = element.attributes.get("onClick");
        assertTrue(className == "container", "Should extract className attribute");
        assertTrue(onClick == "handleClick", "Should extract onClick attribute");
        
        trace("✅ Enhanced parsing test passed");
    }
    
    /**
     * Test error handling improvements
     */
    static function testErrorHandling() {
        trace("TEST: Enhanced error handling");
        
        // Test validation utility
        var validResult = HXXParser.validateJSXStructure('<div>Valid</div>');
        assertTrue(validResult.valid, "Should validate correct JSX");
        assertTrue(validResult.errors.length == 0, "Should have no validation errors");
        
        // Test invalid JSX
        var invalidResult = HXXParser.validateJSXStructure('<div><span></div>');
        assertFalse(invalidResult.valid, "Should detect invalid JSX");
        assertTrue(invalidResult.errors.length > 0, "Should provide error information");
        
        trace("✅ Error handling test passed");
    }
    
    /**
     * Test event handler extraction
     */
    static function testEventHandlerExtraction() {
        trace("TEST: Event handler extraction");
        
        var jsx = '<button onClick="increment" onSubmit="save" phx-click="existing">Click</button>';
        var element = HXXParser.parseJSXElement(jsx);
        var handlers = HXXParser.extractEventHandlers(element.attributes);
        
        assertTrue(handlers.exists("phx-click"), "Should convert onClick to phx-click");
        assertTrue(handlers.exists("phx-submit"), "Should convert onSubmit to phx-submit");
        assertTrue(handlers.exists("phx-click"), "Should preserve existing phx- events");
        
        // Test conversion utility
        var converted = HXXParser.convertReactEventToPhoenix("onClick");
        assertTrue(converted == "phx-click", "Should convert React events correctly");
        
        trace("✅ Event handler extraction test passed");
    }
    
    /**
     * Test binding extraction
     */
    static function testBindingExtraction() {
        trace("TEST: Template binding extraction");
        
        var content = "Hello {user.name}, you have {messageCount} messages";
        var bindings = HXXParser.extractBindings(content);
        
        assertTrue(bindings.length == 2, "Should extract two bindings");
        assertTrue(bindings.contains("user.name"), "Should extract user.name binding");
        assertTrue(bindings.contains("messageCount"), "Should extract messageCount binding");
        
        // Test conditional/loop detection
        var conditionalJSX = "{showContent && <div>Content</div>}";
        var hasConditional = HXXParser.hasConditionalRendering(conditionalJSX);
        assertTrue(hasConditional, "Should detect conditional rendering");
        
        var loopJSX = "{users.map(user => <div>{user.name}</div>)}";
        var hasLoop = HXXParser.hasLoopRendering(loopJSX);
        assertTrue(hasLoop, "Should detect loop rendering");
        
        trace("✅ Binding extraction test passed");
    }
    
    // Test helper functions
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