package;

class Main {
    static function main() {
        var colors = new Map<String, String>();
        colors.set("red", "#FF0000");
        
        // This is the pattern we're trying to detect and transform
        for (name => hex in colors) {
            trace('Color $name = $hex');
        }
    }
}