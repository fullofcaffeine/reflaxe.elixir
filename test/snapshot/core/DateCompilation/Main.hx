class Main {
    static function main() {
        // Test Date static methods
        var now = Date.now();
        var fromTimestamp = Date.fromTime(1234567890000.0);
        var fromString = Date.fromString("2024-01-01T12:00:00Z");
        
        // Test Date instance methods
        var specificDate = new Date(2024, 0, 15, 10, 30, 45);
        var timestamp = specificDate.getTime();
        var year = specificDate.getFullYear();
        var month = specificDate.getMonth();
        var day = specificDate.getDate();
        var dayOfWeek = specificDate.getDay();
        var hours = specificDate.getHours();
        var minutes = specificDate.getMinutes();
        var seconds = specificDate.getSeconds();
        var str = specificDate.toString();
        
        // Test UTC methods
        var utcYear = specificDate.getUTCFullYear();
        var utcMonth = specificDate.getUTCMonth();
        var utcDay = specificDate.getUTCDate();
        var utcHours = specificDate.getUTCHours();
        var offset = specificDate.getTimezoneOffset();
        
        trace("Date compilation test complete");
    }
}