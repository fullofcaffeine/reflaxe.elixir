class Main {
    static function main() {
        // Simple for loop - should be detected and transformed
        for (i in 0...5) {
            trace("Index: " + i);
        }
        
        // For loop with array access - should generate comprehension
        var numbers = [1, 2, 3, 4, 5];
        var doubled = [];
        for (i in 0...numbers.length) {
            doubled.push(numbers[i] * 2);
        }
        
        // Nested for loops
        for (i in 0...3) {
            for (j in 0...3) {
                trace("i=" + i + ", j=" + j);
            }
        }
        
        // For loop with side effects only
        var counter = 0;
        for (k in 0...10) {
            counter++;
        }
        trace("Counter: " + counter);
    }
}