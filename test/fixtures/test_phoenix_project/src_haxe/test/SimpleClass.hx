package test;

class SimpleClass {
    public static function main() {
        trace("Hello from Haxe!");
    }
    
    public static function greet(name: String): String {
        return "Hello, " + name + "!";
    }
}
