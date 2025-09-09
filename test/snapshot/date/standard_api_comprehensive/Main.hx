/**
 * Comprehensive test for standard Haxe Date API
 * Tests all standard methods to ensure compatibility
 */
class Main {
    public static function main() {
        testConstructors();
        testGetters();
        testUTCMethods();
        testConversions();
    }
    
    static function testConstructors() {
        trace("=== Constructor Tests ===");
        
        // Test constructor with specific date
        var d1 = new Date(2024, 0, 15, 10, 30, 45); // January 15, 2024
        trace('Constructor: year=${d1.getFullYear()}, month=${d1.getMonth()}, day=${d1.getDate()}');
        trace('Time: ${d1.getHours()}:${d1.getMinutes()}:${d1.getSeconds()}');
        
        // Test Date.now()
        var now = Date.now();
        trace('Date.now() returned a date: ${now.toString()}');
        
        // Test fromTime
        var timestamp = 1704067200000.0; // Jan 1, 2024 00:00:00 UTC in milliseconds
        var d2 = Date.fromTime(timestamp);
        trace('fromTime(${timestamp}): ${d2.toString()}');
        
        // Test fromString
        var isoString = "2024-03-15T14:30:00Z";
        var d3 = Date.fromString(isoString);
        trace('fromString("${isoString}"): year=${d3.getFullYear()}, month=${d3.getMonth()}');
    }
    
    static function testGetters() {
        trace("=== Getter Tests ===");
        
        // Create a known date: March 15, 2024, 14:30:45
        var d = new Date(2024, 2, 15, 14, 30, 45); // Month is 0-based (2 = March)
        
        trace('getFullYear(): ${d.getFullYear()}'); // Should be 2024
        trace('getMonth(): ${d.getMonth()}'); // Should be 2 (March, 0-based)
        trace('getDate(): ${d.getDate()}'); // Should be 15
        trace('getHours(): ${d.getHours()}'); // Should be 14
        trace('getMinutes(): ${d.getMinutes()}'); // Should be 30
        trace('getSeconds(): ${d.getSeconds()}'); // Should be 45
        
        // Test getDay() - day of week
        // March 15, 2024 is a Friday (5 in Haxe's 0-6 system where Sunday=0)
        trace('getDay(): ${d.getDay()}'); // Should be 5 (Friday)
        
        // Test getTime() - milliseconds since epoch
        var ms = d.getTime();
        trace('getTime(): ${ms} milliseconds since epoch');
        
        // Test toString()
        trace('toString(): ${d.toString()}');
    }
    
    static function testUTCMethods() {
        trace("=== UTC Method Tests ===");
        
        var d = new Date(2024, 5, 21, 8, 15, 30); // June 21, 2024
        
        trace('getUTCFullYear(): ${d.getUTCFullYear()}');
        trace('getUTCMonth(): ${d.getUTCMonth()}');
        trace('getUTCDate(): ${d.getUTCDate()}');
        trace('getUTCDay(): ${d.getUTCDay()}');
        trace('getUTCHours(): ${d.getUTCHours()}');
        trace('getUTCMinutes(): ${d.getUTCMinutes()}');
        trace('getUTCSeconds(): ${d.getUTCSeconds()}');
        trace('getTimezoneOffset(): ${d.getTimezoneOffset()}'); // Should be 0 for UTC
    }
    
    static function testConversions() {
        trace("=== Conversion Tests ===");
        
        // Test month conversion (Haxe 0-based to Elixir 1-based and back)
        var d = new Date(2024, 11, 25, 0, 0, 0); // December (11 in Haxe, should be 12 in Elixir)
        trace('December in Haxe (0-based): month=${d.getMonth()}'); // Should be 11
        
        // Test day of week conversion
        // Create a Sunday (should be 0 in Haxe)
        var sunday = new Date(2024, 0, 7, 0, 0, 0); // January 7, 2024 is a Sunday
        trace('Sunday getDay(): ${sunday.getDay()}'); // Should be 0
        
        // Create a Monday (should be 1 in Haxe)
        var monday = new Date(2024, 0, 8, 0, 0, 0); // January 8, 2024 is a Monday
        trace('Monday getDay(): ${monday.getDay()}'); // Should be 1
        
        // Test roundtrip: create date, get time, create from time
        var original = new Date(2024, 6, 4, 12, 0, 0); // July 4, 2024 noon
        var timestamp = original.getTime();
        var restored = Date.fromTime(timestamp);
        trace('Roundtrip test:');
        trace('  Original: ${original.getFullYear()}-${original.getMonth()}-${original.getDate()}');
        trace('  Restored: ${restored.getFullYear()}-${restored.getMonth()}-${restored.getDate()}');
    }
}