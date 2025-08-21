class TestDebug {
    public static function main() {
        var i = 0;
        // Simple if-else that should compile correctly
        if (i > 0) {
            trace("positive");
        } else {
            trace("not positive");
        }
    }
}