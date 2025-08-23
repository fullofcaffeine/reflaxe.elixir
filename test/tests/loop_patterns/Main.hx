class Main {
    static function main() {
        var numbers = [1, 2, 3, 4, 5];
        
        // Test filter pattern
        var evens = [];
        for (n in numbers) {
            if (n % 2 == 0) {
                evens.push(n);
            }
        }
        
        // Test map pattern  
        var doubled = [];
        for (n in numbers) {
            doubled.push(n * 2);
        }
        
        trace("Evens: " + evens);
        trace("Doubled: " + doubled);
    }
}