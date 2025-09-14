/**
 * Regression Test: Underscore Prefix for Used Variables
 * 
 * BUG FIXED (January 2025): Variables used in TVar initialization expressions
 * (particularly in while loop transformations to Enum.reduce_while) were incorrectly
 * being marked as unused and prefixed with underscores.
 * 
 * ROOT CAUSE: UsageDetector.isVariableUsed() wasn't checking TVar initialization
 * expressions, missing variables used in lambda functions created by loop transformations.
 * 
 * FIX: Added TVar case handling to recursively check initialization expressions.
 * 
 * This test ensures that parameters used in transformed loops are correctly
 * detected as used and NOT prefixed with underscores.
 */
class Main {
    static function main() {
        // Test 1: Simple while loop with parameter usage
        testSimpleWhileLoop("test", 5);
        
        // Test 2: Binary search pattern (like BalancedTree.get)
        var result = binarySearch([1, 3, 5, 7, 9], 5);
        trace("Found: " + result);
        
        // Test 3: Multiple parameters in loop
        processItems(["a", "b", "c"], 10, true);
    }
    
    // This function's 'key' parameter should NOT get underscore prefix
    static function testSimpleWhileLoop(key: String, limit: Int): String {
        var count = 0;
        while (count < limit) {
            if (key == "test") {
                return "Found: " + key;  // 'key' is used here
            }
            count++;
        }
        return "Not found";
    }
    
    // Binary search pattern similar to BalancedTree.get
    // The 'target' parameter should NOT get underscore prefix
    static function binarySearch(arr: Array<Int>, target: Int): Bool {
        var left = 0;
        var right = arr.length - 1;
        
        while (left <= right) {
            var mid = Std.int((left + right) / 2);
            if (arr[mid] == target) {  // 'target' is used here
                return true;
            } else if (arr[mid] < target) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }
        return false;
    }
    
    // Multiple parameters used in loop
    // None of these should get underscore prefixes
    static function processItems(items: Array<String>, maxCount: Int, verbose: Bool): Void {
        var processed = 0;
        var index = 0;
        
        while (index < items.length && processed < maxCount) {
            var item = items[index];
            if (verbose) {  // 'verbose' is used
                trace("Processing: " + item);
            }
            processed++;
            index++;
        }
        
        trace("Processed " + processed + " items out of max " + maxCount);
    }
}