class DateInjectionTest {
    static function main() {
        // Test Date.hx injection
        var date = new Date(2024, 0, 1, 12, 0, 0);
        trace("Date created: " + date.toString());
        trace("Hours: " + date.getHours());
        trace("Timestamp: " + date.getTime());
    }
}