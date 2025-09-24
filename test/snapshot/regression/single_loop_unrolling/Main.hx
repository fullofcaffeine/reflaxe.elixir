package;

class Main {
    static function main() {
        // Simple single loop that should generate Enum.each
        // This gets unrolled when using trace directly
        for (k in 0...3) {
            trace('Index: ' + k);
        }
    }
}