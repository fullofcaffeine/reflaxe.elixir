/**
 * Test for Date.now() static method compilation
 * 
 * This test verifies that Date.now() static method calls are properly
 * compiled to Elixir's DateTime/NaiveDateTime functions.
 */
class Main {
    static function main(): Void {
        testDateNow();
        testDateFromTime();
        testDateComparison();
    }
    
    static function testDateNow(): Void {
        // Test Date.now() static method
        var now: Date = Date.now();
        trace("Current time: " + now.toString());
        
        // Get timestamp
        var timestamp: Float = now.getTime();
        trace("Timestamp: " + timestamp);
    }
    
    static function testDateFromTime(): Void {
        // Test creating Date from timestamp
        var timestamp: Float = 1704067200000; // 2024-01-01 00:00:00 UTC
        var date: Date = Date.fromTime(timestamp);
        trace("Date from timestamp: " + date.toString());
        
        // Test year, month, day
        var year: Int = date.getFullYear();
        var month: Int = date.getMonth();
        var day: Int = date.getDate();
        trace("Year: " + year + ", Month: " + month + ", Day: " + day);
    }
    
    static function testDateComparison(): Void {
        var date1: Date = Date.now();
        var date2: Date = Date.fromTime(date1.getTime() + 1000); // 1 second later
        
        // Compare dates
        var isEarlier: Bool = date1.getTime() < date2.getTime();
        trace("Date1 is earlier than Date2: " + isEarlier);
    }
}