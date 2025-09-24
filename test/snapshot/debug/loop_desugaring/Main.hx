package;

class Main {
    public static function main() {
        // Test 1: Simple for-in-range loop
        trace("=== For in range ===");
        for (i in 0...5) {
            trace(i);
        }
        
        // Test 2: For loop with variable bounds
        trace("=== For with variable bounds ===");
        var start = 0;
        var end = 10;
        for (j in start...end) {
            trace(j * 2);
        }
        
        // Test 3: For-in array
        trace("=== For in array ===");
        var arr = [1, 2, 3, 4, 5];
        for (item in arr) {
            trace(item);
        }
        
        // Test 4: While loop with mutation
        trace("=== While with mutation ===");
        var k = 0;
        while (k < 5) {
            trace(k);
            k++;
        }
        
        // Test 5: Complex for loop (like StringTools.urlEncode)
        trace("=== Complex for loop ===");
        var str = "hello";
        var result = "";
        for (idx in 0...str.length) {
            var c = str.charCodeAt(idx);
            if (c >= 97 && c <= 122) {
                result += String.fromCharCode(c);
            } else {
                result += "%" + StringTools.hex(c, 2);
            }
        }
        trace(result);
    }
}