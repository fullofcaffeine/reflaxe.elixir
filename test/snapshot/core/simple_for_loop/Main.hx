package;

class Main {
    public static function main() {
        // Simple test case - just iterate with while loop for comparison
        var fruits = ["apple", "banana", "orange"];
        
        // First, a simple for loop
        for (fruit in fruits) {
            trace('For: $fruit');
        }
        
        // Now a manual while loop
        var i = 0;
        while (i < fruits.length) {
            trace('While: ${fruits[i]}');
            i++;
        }
    }
}