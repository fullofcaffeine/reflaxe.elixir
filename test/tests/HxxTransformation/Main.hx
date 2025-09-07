/**
 * Test HXX.hxx() to Phoenix ~H sigil transformation
 * 
 * This test verifies that HXX.hxx() calls are properly transformed
 * to Phoenix ~H sigils at compile-time, eliminating runtime errors.
 */
class Main {
    static function main(): Void {
        testSimpleTemplate();
        testTemplateWithVariables();
        testMultilineTemplate();
    }
    
    static function testSimpleTemplate(): String {
        // Simple HXX template without variables
        return HXX.hxx('<div>Hello World</div>');
    }
    
    static function testTemplateWithVariables(): String {
        // Template with Phoenix assigns
        return HXX.hxx('<div class={@userClass}>Hello {@userName}</div>');
    }
    
    static function testMultilineTemplate(): String {
        // Multi-line template
        return HXX.hxx('
            <div class="container">
                <h1><%= @title %></h1>
                <p>{@description}</p>
            </div>
        ');
    }
}