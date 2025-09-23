package;

class Main {
    public static function main() {
        // Test String.cross.hx methods
        var text = "Hello, World!";
        
        // Test indexOf
        trace('Index of "World": ${text.indexOf("World")}');
        trace('Index of "o" from 5: ${text.indexOf("o", 5)}');
        
        // Test lastIndexOf  
        var repeated = "hello hello hello";
        trace('Last index of "hello": ${repeated.lastIndexOf("hello")}');
        trace('Last index of "o": ${repeated.lastIndexOf("o")}');
        
        // Test charAt and charCodeAt
        trace('Character at 0: ${text.charAt(0)}');
        trace('Char code at 0: ${text.charCodeAt(0)}');
        
        // Test split
        var parts = text.split(", ");
        trace('Split result: ${parts}');
        trace('First part: ${parts[0]}');
        
        // Test substr and substring
        trace('Substr(0, 5): ${text.substr(0, 5)}');
        trace('Substring(7, 12): ${text.substring(7, 12)}');
        
        // Test toUpperCase and toLowerCase
        trace('Uppercase: ${text.toUpperCase()}');
        trace('Lowercase: ${text.toLowerCase()}');
        
        // Complex string interpolation with method calls
        var name = "Alice";
        var message = "Hello, ${name.toUpperCase()}! Your name has ${name.length} characters.";
        trace(message);
        
        // Edge cases
        trace('Empty string indexOf: ${"".indexOf("test")}');
        trace('Not found: ${text.indexOf("xyz")}');
        trace('Char at invalid index: ${text.charAt(-1)}');
        trace('Char code at invalid: ${text.charCodeAt(999)}');
    }
}