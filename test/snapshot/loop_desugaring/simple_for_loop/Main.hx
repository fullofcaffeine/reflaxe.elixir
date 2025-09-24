class Main {
    public static function main() {
        // Simple for loop that should be detected and converted to Enum.each
        for (i in 0...5) {
            trace('Number: ' + i);
        }
    }
}