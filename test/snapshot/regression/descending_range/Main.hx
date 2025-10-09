package;

class Main {
    public static function main() {}

    // Build a descending integer range using a comprehension.
    // The printer should preserve ..//-1 for descending ranges.
    static function desc(): Array<Int> {
        return [for (i in 5...0) i];
    }
}

