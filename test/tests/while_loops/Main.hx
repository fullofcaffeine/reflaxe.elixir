package;

class Main {
    public static function main() {
        // Basic while loop
        var i = 0;
        while (i < 5) {
            // Simple operation
            i++;
        }
        
        // Do-while loop
        var j = 0;
        do {
            // Simple operation
            j++;
        } while (j < 3);
        
        // More complex while with multiple operations
        var counter = 10;
        while (counter > 0) {
            counter -= 2;
            if (counter == 4) break;
        }
        
        // While with continue
        var k = 0;
        var evens = [];
        while (k < 10) {
            k++;
            if (k % 2 != 0) continue;
            evens.push(k);
        }
        
        // Infinite loop with break
        var count = 0;
        while (true) {
            count++;
            if (count == 10) break;
        }
        
        // Nested while loops
        var outer = 0;
        while (outer < 3) {
            var inner = 0;
            while (inner < 2) {
                trace('Nested: $outer, $inner');
                inner++;
            }
            outer++;
        }
        
        // While with complex condition
        var a = 0;
        var b = 10;
        while (a < 5 && b > 5) {
            a++;
            b--;
        }
        
        // Do-while with break
        var x = 0;
        do {
            x++;
            if (x == 5) break;
        } while (x < 10);
        
        trace("Final i: " + i);
        trace("Final j: " + j);
        trace("Final counter: " + counter);
        trace("Evens: " + evens);
        trace("Count from infinite: " + count);
        trace("Complex condition result: a=" + a + ", b=" + b);
        trace("Do-while with break: x=" + x);
    }
}