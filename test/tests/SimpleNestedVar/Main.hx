// Simple test case for variable declaration in nested if within loop
class Main {
    static function main() {
        var items = [1, 2, 3, 4, 5];
        var i = 0;
        
        while (i < items.length) {
            var item = items[i];
            i++;
            
            if (item > 2) {
                var doubled = item * 2;  // This declaration should be preserved
                trace(doubled);
            }
        }
    }
}