class Test {
    static function main() {
        var items = [1, 2, 3, 4, 5];
        
        // Test Lambda.fold
        var sum = Lambda.fold(items, function(x, acc) return x + acc, 0);
        trace("Sum: " + sum);
    }
}