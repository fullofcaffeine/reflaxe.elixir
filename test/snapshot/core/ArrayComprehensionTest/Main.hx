class Main {
    static function main() {
        // Simple array comprehension
        var squares = [for (i in 0...5) i * i];
        trace(squares); // Should be [0, 1, 4, 9, 16]
        
        // Nested array comprehension
        var matrix = [for (i in 0...3) [for (j in 0...3) i * 3 + j]];
        trace(matrix); // Should be [[0,1,2], [3,4,5], [6,7,8]]
        
        // Array comprehension with condition
        var evens = [for (i in 0...10) if (i % 2 == 0) i];
        trace(evens); // Should be [0, 2, 4, 6, 8]
        
        // Comprehension with variable capture
        var multiplier = 2;
        var doubled = [for (i in 0...5) i * multiplier];
        trace(doubled); // Should be [0, 2, 4, 6, 8]
    }
}