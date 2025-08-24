@:native("TestModule")
extern class TestClass {
    @:native("native_method")
    static function originalMethod(arg: String): String;
}

class Main {
    static function main() {
        var result = TestClass.originalMethod("test");
    }
}
