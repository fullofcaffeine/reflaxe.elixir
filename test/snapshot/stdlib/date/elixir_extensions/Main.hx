import elixir.DateTime.TimeUnit;
import elixir.DateTime.TimePrecision;
import elixir.DateTime.ComparisonResult;

/**
 * Test for Elixir-specific Date extensions
 * Tests the native Elixir methods added to the Date abstraction
 */
class Main {
    public static function main() {
        testArithmetic();
        testComparisons();
        testConversions();
        testUtilityMethods();
        testOperators();
    }
    
    static function testArithmetic() {
        trace("=== Arithmetic Operations ===");
        
        var d = new Date(2024, 0, 15, 12, 0, 0); // January 15, 2024 noon
        
        // Test add() with different units
        var tomorrow = d.add(1, TimeUnit.Day);
        trace('Add 1 day: ${d.getDate()} -> ${tomorrow.getDate()}');
        
        var nextWeek = d.add(7, TimeUnit.Day);
        trace('Add 7 days: ${d.getDate()} -> ${nextWeek.getDate()}');
        
        var inAnHour = d.add(1, TimeUnit.Hour);
        trace('Add 1 hour: ${d.getHours()}:00 -> ${inAnHour.getHours()}:00');
        
        var in30Min = d.add(30, TimeUnit.Minute);
        trace('Add 30 minutes: ${d.getMinutes()} min -> ${in30Min.getMinutes()} min');
        
        // Test diff() between dates
        var d1 = new Date(2024, 0, 1, 0, 0, 0);
        var d2 = new Date(2024, 0, 15, 0, 0, 0);
        var daysDiff = d2.diff(d1, TimeUnit.Day);
        trace('Days between Jan 1 and Jan 15: ${daysDiff}');
        
        var hoursDiff = d2.diff(d1, TimeUnit.Hour);
        trace('Hours between Jan 1 and Jan 15: ${hoursDiff}');
    }
    
    static function testComparisons() {
        trace("=== Comparison Methods ===");
        
        var d1 = new Date(2024, 0, 15, 12, 0, 0);
        var d2 = new Date(2024, 0, 16, 12, 0, 0);
        var d3 = new Date(2024, 0, 15, 12, 0, 0); // Same as d1
        
        // Test compare() method
        var result1 = d1.compare(d2);
        trace('d1.compare(d2): ${result1}'); // Should be Lt
        
        var result2 = d2.compare(d1);
        trace('d2.compare(d1): ${result2}'); // Should be Gt
        
        var result3 = d1.compare(d3);
        trace('d1.compare(d3): ${result3}'); // Should be Eq
        
        // Test convenience methods
        trace('d1.isBefore(d2): ${d1.isBefore(d2)}'); // Should be true
        trace('d2.isAfter(d1): ${d2.isAfter(d1)}'); // Should be true
        trace('d1.isEqual(d3): ${d1.isEqual(d3)}'); // Should be true
    }
    
    static function testConversions() {
        trace("=== Conversion Methods ===");
        
        var d = new Date(2024, 5, 21, 14, 30, 45); // June 21, 2024
        
        // Test conversion to NaiveDateTime
        var naive = d.toNaiveDateTime();
        trace('Converted to NaiveDateTime');
        
        // Test conversion to Elixir Date (date only)
        var dateOnly = d.toElixirDate();
        trace('Converted to Elixir Date (date only)');
        
        // Test creating from NaiveDateTime
        var fromNaive = Date.fromNaiveDateTime(naive);
        trace('Created Date from NaiveDateTime: ${fromNaive.toString()}');
    }
    
    static function testUtilityMethods() {
        trace("=== Utility Methods ===");
        
        var d = new Date(2024, 2, 15, 14, 30, 45); // March 15, 2024, 14:30:45
        
        // Test truncate()
        var truncatedToMin = d.truncate(TimePrecision.Second);
        trace('Truncated to seconds: ${d.getSeconds()} -> clean seconds');
        
        // Test format() with strftime patterns
        var formatted = d.format("%Y-%m-%d %H:%M:%S");
        trace('Formatted date: ${formatted}');
        
        var shortFormat = d.format("%b %d, %Y");
        trace('Short format: ${shortFormat}');
        
        // Test beginningOfDay and endOfDay
        var startOfDay = d.beginningOfDay();
        trace('Beginning of day: ${startOfDay.getHours()}:${startOfDay.getMinutes()}:${startOfDay.getSeconds()}');
        
        var endOfDay = d.endOfDay();
        trace('End of day: ${endOfDay.getHours()}:${endOfDay.getMinutes()}:${endOfDay.getSeconds()}');
    }
    
    static function testOperators() {
        trace("=== Operator Overloading ===");
        
        var d1 = new Date(2024, 0, 15, 12, 0, 0);
        var d2 = new Date(2024, 0, 16, 12, 0, 0);
        var d3 = new Date(2024, 0, 15, 12, 0, 0); // Same as d1
        
        // Test comparison operators
        trace('d1 < d2: ${d1 < d2}'); // Should be true
        trace('d1 > d2: ${d1 > d2}'); // Should be false
        trace('d1 <= d3: ${d1 <= d3}'); // Should be true (equal)
        trace('d1 >= d3: ${d1 >= d3}'); // Should be true (equal)
        trace('d1 == d3: ${d1 == d3}'); // Should be true
        trace('d1 != d2: ${d1 != d2}'); // Should be true
    }
}
