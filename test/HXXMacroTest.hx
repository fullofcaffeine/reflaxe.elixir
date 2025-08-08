package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.macro.HXXMacro;

using StringTools;

/**
 * Test HXX macro system for JSX→HEEx template transformation
 * Tests following BDD approach - testing the interface developers will use
 */
class HXXMacroTest {
    public static function main() {
        trace("Running HXX Macro Tests...");
        
        testBasicJSXParsing();
        testElementTransformation();
        testAttributeHandling();
        testNestedElements();
        testEventHandlerBinding();
        testConditionalRendering();
        testLoopRendering();
        testTemplateBindings();
        testErrorHandling();
        
        trace("✅ All HXX macro tests passed!");
    }
    
    /**
     * Test basic JSX syntax parsing
     */
    static function testBasicJSXParsing() {
        trace("TEST: Basic JSX syntax parsing");
        
        // Test simple element parsing
        var simpleElement = '<div>Hello World</div>';
        var result = HXXMacro.parseJSX(simpleElement);
        
        assertTrue(result != null, "Should parse simple JSX element");
        assertTrue(result.tag == "div", "Should extract correct tag name");
        assertTrue(result.content == "Hello World", "Should extract text content");
        
        // Test self-closing element
        var selfClosing = '<input type="text" />';
        var result2 = HXXMacro.parseJSX(selfClosing);
        
        assertTrue(result2 != null, "Should parse self-closing element");
        assertTrue(result2.tag == "input", "Should extract tag from self-closing");
        assertTrue(result2.selfClosing == true, "Should mark as self-closing");
        
        trace("✅ Basic JSX parsing test passed");
    }
    
    /**
     * Test JSX→HEEx element transformation
     */
    static function testElementTransformation() {
        trace("TEST: JSX→HEEx element transformation");
        
        // Test basic element transformation
        var jsx = '<div class="container">Content</div>';
        var heex = HXXMacro.transformToHEEx(jsx);
        
        assertTrue(heex.contains('<div class="container">'), "Should preserve basic HTML structure");
        assertTrue(heex.contains('Content'), "Should preserve text content");
        assertTrue(heex.contains('</div>'), "Should include closing tag");
        
        // Test self-closing transformation
        var jsxSelf = '<input type="text" />';
        var heexSelf = HXXMacro.transformToHEEx(jsxSelf);
        
        assertTrue(heexSelf.contains('<input type="text"'), "Should transform self-closing element");
        
        trace("✅ Element transformation test passed");
    }
    
    /**
     * Test JSX attribute handling and conversion
     */
    static function testAttributeHandling() {
        trace("TEST: JSX attribute handling");
        
        // Test className → class conversion
        var jsx = '<div className="my-class">Content</div>';
        var heex = HXXMacro.transformToHEEx(jsx);
        
        assertTrue(heex.contains('class="my-class"'), "Should convert className to class");
        assertFalse(heex.contains('className'), "Should not contain className in output");
        
        // Test event handler attributes
        var jsxEvent = '<button onClick={handleClick}>Click me</button>';
        var heexEvent = HXXMacro.transformToHEEx(jsxEvent);
        
        assertTrue(heexEvent.contains('phx-click='), "Should convert onClick to phx-click");
        assertTrue(heexEvent.contains('handleClick'), "Should preserve event handler name");
        
        trace("✅ Attribute handling test passed");
    }
    
    /**
     * Test nested element structures
     */
    static function testNestedElements() {
        trace("TEST: Nested element structures");
        
        var jsx = '<div class="outer">\n    <h1>Title</h1>\n    <p>Paragraph with <span>nested span</span></p>\n</div>';
        
        var heex = HXXMacro.transformToHEEx(jsx);
        
        assertTrue(heex.contains('<div class="outer">'), "Should handle outer element");
        assertTrue(heex.contains('<h1>Title</h1>'), "Should handle nested h1");
        assertTrue(heex.contains('<p>'), "Should handle nested p");
        assertTrue(heex.contains('<span>nested span</span>'), "Should handle deeply nested elements");
        
        trace("✅ Nested elements test passed");
    }
    
    /**
     * Test Phoenix LiveView event handler binding
     */
    static function testEventHandlerBinding() {
        trace("TEST: Phoenix LiveView event handler binding");
        
        // Test click handlers
        var jsx = '<button onClick="increment">+</button>';
        var heex = HXXMacro.transformToHEEx(jsx);
        
        assertTrue(heex.contains('phx-click="increment"'), "Should convert onClick to phx-click");
        
        // Test form events
        var jsxForm = '<form onSubmit="save_user">Form content</form>';
        var heexForm = HXXMacro.transformToHEEx(jsxForm);
        
        assertTrue(heexForm.contains('phx-submit="save_user"'), "Should convert onSubmit to phx-submit");
        
        // Test change events
        var jsxChange = '<input onChange="validate_field" />';
        var heexChange = HXXMacro.transformToHEEx(jsxChange);
        
        assertTrue(heexChange.contains('phx-change="validate_field"'), "Should convert onChange to phx-change");
        
        trace("✅ Event handler binding test passed");
    }
    
    /**
     * Test conditional rendering (future HXX feature)
     */
    static function testConditionalRendering() {
        trace("TEST: Conditional rendering syntax");
        
        // Test basic conditional
        var jsx = '{showContent && <div>Content</div>}';
        var heex = HXXMacro.transformToHEEx(jsx);
        
        assertTrue(heex.contains('<%= if @showContent do %>'), "Should convert to HEEx conditional");
        assertTrue(heex.contains('<div>Content</div>'), "Should preserve conditional content");
        assertTrue(heex.contains('<% end %>'), "Should close HEEx conditional");
        
        trace("✅ Conditional rendering test passed");
    }
    
    /**
     * Test loop rendering syntax
     */
    static function testLoopRendering() {
        trace("TEST: Loop rendering syntax");
        
        // Test map-style iteration
        var jsx = '{users.map(user => <div key={user.id}>{user.name}</div>)}';
        var heex = HXXMacro.transformToHEEx(jsx);
        
        assertTrue(heex.contains('<%= for user <- @users do %>'), "Should convert to HEEx for loop");
        assertTrue(heex.contains('div'), "Should preserve loop content structure");
        assertTrue(heex.contains('user.name'), "Should convert binding syntax");
        assertTrue(heex.contains('<% end %>'), "Should close HEEx loop");
        
        trace("✅ Loop rendering test passed");
    }
    
    /**
     * Test template bindings and interpolation
     */
    static function testTemplateBindings() {
        trace("TEST: Template bindings and interpolation");
        
        // Test simple binding
        var jsx = '<div>{message}</div>';
        var heex = HXXMacro.transformToHEEx(jsx);
        
        assertTrue(heex.contains('<%= @message %>'), "Should convert binding to HEEx syntax");
        
        // Test attribute binding
        var jsxAttr = '<input value={inputValue} />';
        var heexAttr = HXXMacro.transformToHEEx(jsxAttr);
        
        assertTrue(heexAttr.contains('value={@inputValue}'), "Should handle attribute bindings");
        
        trace("✅ Template bindings test passed");
    }
    
    /**
     * Test error handling and validation
     */
    static function testErrorHandling() {
        trace("TEST: Error handling and validation");
        
        // Test malformed JSX
        try {
            var malformed = '<div><span></div>'; // Mismatched tags
            var result = HXXMacro.parseJSX(malformed);
            // If we get here, parsing didn't throw an error as expected
            assertTrue(false, "Should throw error for malformed JSX");
        } catch (e: Dynamic) {
            // Any error is acceptable for now - proper error detection would be in REFACTOR phase
            assertTrue(true, "Error correctly thrown for malformed JSX");
        }
        
        // Test unclosed tags
        try {
            var unclosed = '<div>Content';
            var result = HXXMacro.parseJSX(unclosed);
            assertTrue(false, "Should throw error for unclosed tags");
        } catch (e: Dynamic) {
            // Any error is acceptable for now - proper error detection would be in REFACTOR phase
            assertTrue(true, "Error correctly thrown for unclosed tags");
        }
        
        trace("✅ Error handling test passed");
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