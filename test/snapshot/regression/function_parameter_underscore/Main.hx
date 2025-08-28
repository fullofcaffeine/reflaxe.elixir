/**
 * Regression test for function parameter underscore prefix bug
 * 
 * ISSUE: Function parameters like 'appName' were being compiled to '_app_name' incorrectly,
 * causing undefined variable errors in the generated Elixir code.
 * 
 * EXPECTED: Parameters should maintain their names without unwanted underscore prefixes
 * unless they are truly unused (which function parameters never are by definition).
 */
class Main {
    static function main() {
        // Test regular function parameters
        testFunction("TodoApp", 42, true);
        
        // Test optional parameters
        testOptional("MyApp");
        testOptional("MyApp", 8080);
        
        // Test parameters used in string concatenation
        var result = buildName("Phoenix", "App");
        trace(result);
        
        // Test parameters used as method receivers
        var processed = processConfig({name: "test"});
        trace(processed);
    }
    
    static function testFunction(appName: String, port: Int, enabled: Bool): String {
        // All parameters are used - none should get underscore prefix
        var config = appName + ".Config";
        var url = "http://localhost:" + port;
        var status = enabled ? "active" : "inactive";
        return config + " at " + url + " is " + status;
    }
    
    static function testOptional(appName: String, ?port: Int): String {
        // Optional parameter with default handling
        var actualPort = port != null ? port : 4000;
        return appName + " on port " + actualPort;
    }
    
    static function buildName(prefix: String, suffix: String): String {
        // Parameters used in concatenation
        return prefix + "." + suffix;
    }
    
    static function processConfig(config: Dynamic): String {
        // Parameter used as object
        return Std.string(config.name);
    }
}