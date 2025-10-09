class Main {
    static function main() {
        var sum = 0;
        var i = 0;
        // Use early exit to force reduce_while shape
        while (i < 10) {
            sum = sum + i;
            if (i == 5) break;
            i = i + 1;
        }
        trace(sum);
    }
}
