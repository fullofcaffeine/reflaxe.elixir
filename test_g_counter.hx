class TestGCounter {
    public static function main() {
        var str = "HELLO";
        
        // This will generate a switch with Haxe's 'g' variable
        var result = switch(str.toLowerCase()) {
            case "error": "Error found";
            case "info": "Info found";
            case "hello": "Hello found";
            case _: "Unknown";
        }
        
        trace(result);
    }
}