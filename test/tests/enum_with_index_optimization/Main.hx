class Main {
    public static function main() {
        // Test various patterns that should use Enum.with_index
        testBasicIndexedIteration();
        testIndexedMap();
        testIndexedFilter();
        testComplexIndexedOperation();
    }
    
    // Basic for loop with index tracking
    static function testBasicIndexedIteration() {
        var items = ["apple", "banana", "cherry"];
        var results = [];
        
        for (i in 0...items.length) {
            var item = items[i];
            results.push('${i}: ${item}');
        }
        
        trace(results);
    }
    
    // Map with index
    static function testIndexedMap(): Array<String> {
        var items = ["first", "second", "third"];
        var indexed = [];
        
        for (i in 0...items.length) {
            indexed.push('Item #${i + 1}: ${items[i]}');
        }
        
        return indexed;
    }
    
    // Filter based on index
    static function testIndexedFilter(): Array<String> {
        var items = ["a", "b", "c", "d", "e"];
        var evenIndexed = [];
        
        for (i in 0...items.length) {
            if (i % 2 == 0) {
                evenIndexed.push(items[i]);
            }
        }
        
        return evenIndexed;
    }
    
    // Complex operation with both index and value
    static function testComplexIndexedOperation(): Int {
        var numbers = [10, 20, 30, 40, 50];
        var sum = 0;
        
        for (i in 0...numbers.length) {
            // Weighted sum: value * (index + 1)
            sum += numbers[i] * (i + 1);
        }
        
        return sum;
    }
}