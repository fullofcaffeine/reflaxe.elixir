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
    }
}