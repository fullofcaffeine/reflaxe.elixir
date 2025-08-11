package test.generator;

import utest.Test;
import utest.Assert;
import reflaxe.elixir.generator.TemplateEngine;
using StringTools;

/**
 * Template Engine Test Suite
 * 
 * Tests template processing functionality including:
 * - Placeholder replacement
 * - Conditional blocks
 * - Loops and iterations
 * - Edge cases and error handling
 */
class TemplateEngineTest extends Test {
    
    var engine: TemplateEngine;
    
    public function setup() {
        engine = new TemplateEngine();
    }
    
    // === PLACEHOLDER REPLACEMENT TESTS ===
    
    function testSimplePlaceholderReplacement() {
        var content = "Hello __PROJECT_NAME__, version __VERSION__";
        var replacements = {
            PROJECT_NAME: "MyProject",
            VERSION: "1.0.0"
        };
        
        var result = engine.processContent(content, replacements);
        Assert.equals("Hello MyProject, version 1.0.0", result, "Placeholders should be replaced");
    }
    
    function testMissingPlaceholderPreservation() {
        var content = "Name: __PROJECT_NAME__, Unknown: __UNKNOWN__";
        var replacements = {
            PROJECT_NAME: "TestProject"
        };
        
        var result = engine.processContent(content, replacements);
        Assert.isTrue(result.indexOf("TestProject") >= 0, "Known placeholder should be replaced");
        Assert.isTrue(result.indexOf("__UNKNOWN__") >= 0, "Unknown placeholder should be preserved");
    }
    
    function testCaseInsensitivePlaceholders() {
        var content = "__PROJECT_NAME__ and __project_name__";
        var replacements = {
            PROJECT_NAME: "MyApp",
            project_name: "myapp"
        };
        
        var result = engine.processContent(content, replacements);
        Assert.equals("MyApp and myapp", result, "Should handle different cases");
    }
    
    // === CONDITIONAL BLOCK TESTS ===
    
    function testIfConditionalBlock() {
        var content = "Start\n{{#if authentication}}Auth enabled{{/if}}\nEnd";
        
        var withAuth = engine.processContent(content, {authentication: true});
        Assert.isTrue(withAuth.indexOf("Auth enabled") >= 0, "Should include block when true");
        
        var withoutAuth = engine.processContent(content, {authentication: false});
        Assert.isTrue(withoutAuth.indexOf("Auth enabled") < 0, "Should exclude block when false");
    }
    
    function testUnlessConditionalBlock() {
        var content = "{{#unless skipTests}}Tests included{{/unless}}";
        
        var withTests = engine.processContent(content, {skipTests: false});
        Assert.isTrue(withTests.indexOf("Tests included") >= 0, "Should include when condition is false");
        
        var withoutTests = engine.processContent(content, {skipTests: true});
        Assert.isTrue(withoutTests.indexOf("Tests included") < 0, "Should exclude when condition is true");
    }
    
    function testNestedConditionals() {
        var content = "{{#if web}}Web app{{#if liveview}} with LiveView{{/if}}{{/if}}";
        
        var webWithLiveView = engine.processContent(content, {web: true, liveview: true});
        Assert.equals("Web app with LiveView", webWithLiveView.trim(), "Nested conditions should work");
        
        var webOnly = engine.processContent(content, {web: true, liveview: false});
        Assert.equals("Web app", webOnly.trim(), "Partial nested conditions should work");
        
        var neither = engine.processContent(content, {web: false, liveview: false});
        Assert.equals("", neither.trim(), "All conditions false should produce empty");
    }
    
    function testEqualityConditionals() {
        var content = '{{#if type=="phoenix"}}Phoenix project{{/if}}';
        
        var phoenix = engine.processContent(content, {type: "phoenix"});
        Assert.isTrue(phoenix.indexOf("Phoenix project") >= 0, "Equality check should work");
        
        var basic = engine.processContent(content, {type: "basic"});
        Assert.isTrue(basic.indexOf("Phoenix project") < 0, "Inequality should exclude block");
    }
    
    // === LOOP TESTS ===
    
    function testEachLoop() {
        var content = '{{#each dependencies}}  - {{item}}\n{{/each}}';
        var context = {
            dependencies: ["haxe", "elixir", "phoenix"]
        };
        
        var result = engine.processContent(content, context);
        Assert.isTrue(result.indexOf("haxe") >= 0, "Should include first item");
        Assert.isTrue(result.indexOf("elixir") >= 0, "Should include second item");
        Assert.isTrue(result.indexOf("phoenix") >= 0, "Should include third item");
    }
    
    function testEachWithObjects() {
        var content = '{{#each users}}Name: {{name}}, Age: {{age}}\n{{/each}}';
        var context = {
            users: [
                {name: "Alice", age: 30},
                {name: "Bob", age: 25}
            ]
        };
        
        var result = engine.processContent(content, context);
        Assert.isTrue(result.indexOf("Alice") >= 0, "Should include first user name");
        Assert.isTrue(result.indexOf("30") >= 0, "Should include first user age");
        Assert.isTrue(result.indexOf("Bob") >= 0, "Should include second user name");
        Assert.isTrue(result.indexOf("25") >= 0, "Should include second user age");
    }
    
    // === FILE HANDLING TESTS ===
    
    function testShouldIncludeFile() {
        var context = {authentication: true, database: "postgres"};
        
        Assert.isTrue(engine.shouldIncludeFile("auth.hx.if-authentication", context), 
            "Should include file with matching if condition");
        
        Assert.isFalse(engine.shouldIncludeFile("simple.hx.unless-authentication", context),
            "Should exclude file with matching unless condition");
        
        Assert.isTrue(engine.shouldIncludeFile("regular.hx", context),
            "Should include regular files without conditions");
    }
    
    function testCleanFilename() {
        Assert.equals("auth.hx", engine.cleanFilename("auth.hx.if-authentication"),
            "Should remove if suffix");
        
        Assert.equals("simple.hx", engine.cleanFilename("simple.hx.unless-phoenix"),
            "Should remove unless suffix");
        
        Assert.equals("normal.hx", engine.cleanFilename("normal.hx"),
            "Should preserve normal filenames");
    }
    
    function testTransformFilename() {
        var replacements = {
            PROJECT_NAME: "MyApp",
            MODULE: "Users"
        };
        
        var result = engine.transformFilename("__PROJECT_NAME___controller.ex", replacements);
        Assert.equals("MyApp_controller.ex", result, "Should replace placeholders in filename");
        
        var multi = engine.transformFilename("__MODULE__.__PROJECT_NAME__.ex", replacements);
        Assert.equals("Users.MyApp.ex", multi, "Should replace multiple placeholders");
    }
    
    // === CONTEXT CREATION TESTS ===
    
    function testCreateContext() {
        var options = {
            name: "test-project",
            type: "phoenix",
            database: "postgres"
        };
        
        var context = TemplateEngine.createContext(options);
        
        Assert.equals("test-project", Reflect.field(context, "PROJECT_NAME"));
        Assert.equals("test-project", Reflect.field(context, "PROJECT_NAME_LOWER"));
        Assert.equals("TEST-PROJECT", Reflect.field(context, "PROJECT_NAME_UPPER"));
        Assert.equals("TestProject", Reflect.field(context, "PROJECT_MODULE"));
        Assert.isTrue(Reflect.field(context, "is_phoenix"), "Should set phoenix flag");
        Assert.isFalse(Reflect.field(context, "is_basic"), "Should not set basic flag");
        Assert.isTrue(Reflect.field(context, "is_web"), "Should set web flag for phoenix");
    }
    
    // === ERROR HANDLING TESTS ===
    
    function testMalformedConditionals() {
        var content = "{{#if unclosed}}Content";
        var result = engine.processContent(content, {});
        // Should not crash, just return content as-is or partially processed
        Assert.notNull(result, "Should handle malformed conditionals gracefully");
    }
    
    function testEmptyContext() {
        var content = "__PROJECT_NAME__ {{#if feature}}Feature{{/if}}";
        var result = engine.processContent(content, {});
        
        Assert.isTrue(result.indexOf("__PROJECT_NAME__") >= 0, "Should preserve placeholders without context");
        Assert.isTrue(result.indexOf("Feature") < 0, "Should exclude conditional blocks without context");
    }
    
    function testNullValues() {
        var content = "Value: __NULL_VALUE__";
        var context = {NULL_VALUE: null};
        
        var result = engine.processContent(content, context);
        Assert.equals("Value: __NULL_VALUE__", result, "Should preserve placeholder for null values");
    }
    
    // === PERFORMANCE TESTS ===
    
    @:timeout(1000)
    function testLargeTemplatePerformance() {
        var content = "";
        for (i in 0...1000) {
            content += '__PLACEHOLDER_${i}__ ';
        }
        
        var replacements = {};
        for (i in 0...1000) {
            Reflect.setField(replacements, 'PLACEHOLDER_$i', 'value$i');
        }
        
        var startTime = haxe.Timer.stamp();
        var result = engine.processContent(content, replacements);
        var duration = (haxe.Timer.stamp() - startTime) * 1000;
        
        Assert.isTrue(duration < 100, 'Large template should process in <100ms, took ${duration}ms');
        Assert.isTrue(result.indexOf("value999") >= 0, "Should replace all placeholders");
    }
    
    // === EDGE CASES ===
    
    function testSpecialCharactersInContent() {
        var content = "Project: __NAME__ with $special @chars #tags";
        var replacements = {NAME: "Test&Project"};
        
        var result = engine.processContent(content, replacements);
        Assert.isTrue(result.indexOf("Test&Project") >= 0, "Should handle special characters");
        Assert.isTrue(result.indexOf("$special") >= 0, "Should preserve other special characters");
    }
    
    function testUnicodeSupport() {
        var content = "__GREETING__ 世界";
        var replacements = {GREETING: "你好"};
        
        var result = engine.processContent(content, replacements);
        Assert.equals("你好 世界", result, "Should support Unicode characters");
    }
    
    function testEmptyContent() {
        var result = engine.processContent("", {PROJECT: "Test"});
        Assert.equals("", result, "Empty content should return empty");
    }
    
    function testWhitespacePreservation() {
        var content = "  __NAME__  \n\t__VERSION__  ";
        var replacements = {NAME: "App", VERSION: "1.0"};
        
        var result = engine.processContent(content, replacements);
        Assert.equals("  App  \n\t1.0  ", result, "Should preserve whitespace");
    }
}