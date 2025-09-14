class Main {
    public static function main() {
        // Test Date.now()
        var currentDate: Date = Date.now();
        trace("Current date created");
        
        // Test Date.fromTime()
        var timestamp: Float = 1609459200000.0; // 2021-01-01 00:00:00 UTC
        var dateFromTime: Date = Date.fromTime(timestamp);
        trace("Date from timestamp created");
        
        // Test Date.fromString()
        var dateString: String = "2021-01-01T00:00:00Z";
        var dateFromString: Date = Date.fromString(dateString);
        trace("Date from string created");
        
        // Test instance methods
        var year: Int = currentDate.getFullYear();
        var month: Int = currentDate.getMonth();
        var day: Int = currentDate.getDate();
        var hour: Int = currentDate.getHours();
        var minute: Int = currentDate.getMinutes();
        var second: Int = currentDate.getSeconds();
        
        trace("Year: " + year);
        trace("Month: " + month);
        trace("Day: " + day);
        trace("Hour: " + hour);
        trace("Minute: " + minute);
        trace("Second: " + second);
        
        // Test getTime()
        var time: Float = currentDate.getTime();
        trace("Time in milliseconds: " + time);
        
        // Test toString()
        var dateStr: String = currentDate.toString();
        trace("Date string: " + dateStr);
    }
}