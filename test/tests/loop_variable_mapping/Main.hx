class Main {
    static function main() {
        // Test case demonstrating variable name collision in desugared for loops
        var array = [1, 2, 3, 4, 5];
        var result = [];
        
        // This for loop gets desugared by Haxe into a while loop
        // with both counter and limit variables named 'g' (different TVar.id)
        for (item in array) {
            if (item > 2) {
                result.push(item * 2);
            }
        }
        
        // Nested loop to test proper variable isolation
        for (i in 0...array.length) {
            for (j in 0...array.length) {
                if (array[i] < array[j]) {
                    result.push(array[i] + array[j]);
                }
            }
        }
        
        // Another pattern that triggers desugaring
        var filtered = [];
        for (x in array) {
            if (x % 2 == 0) {
                filtered.push(x);
            }
        }
        
        trace(result);
        trace(filtered);
    }
}