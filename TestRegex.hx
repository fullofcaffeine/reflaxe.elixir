class TestRegex {
    static function main() {
        var line = '\t"id": 23,';
        var regex = ~/^\s*"id"\s*:\s*\d+/;
        trace("Line: " + line);
        trace("Matches: " + regex.match(line));
    }
}
