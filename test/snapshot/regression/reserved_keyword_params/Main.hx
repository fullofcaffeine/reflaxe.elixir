/**
 * Test reserved keyword parameter handling
 * 
 * This test ensures that Elixir reserved keywords used as function parameters
 * are properly escaped with a suffix (e.g., "end" becomes "end_param").
 * 
 * Fixed in commit: db85ccd
 */
class Main {
    static function main() {
        // Test Elixir reserved keywords that Haxe allows as parameters
        // Note: Some keywords like "do", "if", "else", "case", "import" are also Haxe keywords
        testEnd("hello", "world");
        testAfter(100);
        testRescue("exception");
        testDef("definition");
        testDefp("private");
        testDefmodule("MyModule");
        testAlias("MyAlias");
        testReceive("message");
        testQuote("expression");
        testUnquote("value");
        testRequire("library");
        testUse("framework");
        
        // Test multiple reserved keywords
        testMultiple("start", "middle", "result");
    }
    
    // Functions with Elixir reserved keyword parameters (that Haxe allows)
    static function testEnd(start: String, end: String): String {
        return start + " to " + end;
    }
    
    static function testAfter(after: Int): Int {
        return after + 1;
    }
    
    static function testRescue(rescue: String): String {
        return "rescued: " + rescue;
    }
    
    static function testDef(def: String): String {
        return "def: " + def;
    }
    
    static function testDefp(defp: String): String {
        return "defp: " + defp;
    }
    
    static function testDefmodule(defmodule: String): String {
        return "module: " + defmodule;
    }
    
    static function testAlias(alias: String): String {
        return "alias: " + alias;
    }
    
    static function testReceive(receive: String): String {
        return "received: " + receive;
    }
    
    static function testQuote(quote: String): String {
        return "quoted: " + quote;
    }
    
    static function testUnquote(unquote: String): String {
        return "unquoted: " + unquote;
    }
    
    static function testRequire(require: String): String {
        return "required: " + require;
    }
    
    static function testUse(use: String): String {
        return "using: " + use;
    }
    
    // Test multiple reserved keywords in one function
    static function testMultiple(start: String, end: String, after: String): String {
        return start + " -> " + end + " (after: " + after + ")";
    }
}