package;

// EXPERIMENT 1: @:native on regular (non-extern) class
@:native("ElixirModuleName")
class RegularClassWithNative {
    public static function test(): String {
        return "Testing @:native on regular class";
    }
}

// EXPERIMENT 2: @:native on methods in regular class
class RegularClassMethodNative {
    @:native("elixir_method_name")
    public static function haxeMethodName(): String {
        return "Testing @:native on regular method";
    }
}

// EXPERIMENT 3: Regular class trying to map to Enum
@:native("Enum")
class LambdaAsRegular {
    @:native("map")
    public static function map<A,B>(it: Array<A>, f: A -> B): Array<B> {
        // Will this generate Enum.map calls?
        return untyped __elixir__("Enum.map({0}, {1})", it, f);
    }
}

// EXPERIMENT 4: Abstract with @:native
@:native("Enum")
abstract LambdaAbstract(Dynamic) {
    @:native("reduce")
    public static inline function fold<A,B>(it: Array<A>, f: (A,B) -> B, init: B): B {
        return untyped __elixir__("Enum.reduce({0}, {2}, {1})", it, f, init);
    }
}

// EXPERIMENT 5: Enum with @:native
@:native("ElixirAtomName")
enum EnumWithNative {
    OptionOne;
    OptionTwo;
}

// EXPERIMENT 6: Interface with @:native
@:native("ElixirProtocol")
interface InterfaceWithNative {
    function implementMe(): String;
}

// EXPERIMENT 7: Typedef with @:native (likely won't work)
@:native("ElixirType")
typedef TypedefWithNative = {
    field: String
}

// EXPERIMENT 8: @:extern vs extern class
@:extern class ExternMetadata {
    // @:extern metadata on class (different from extern keyword)
    static function test(): Void {}
}

// EXPERIMENT 9: Other related metadata
@:nativeGen  // Marks type for native code generation
class NativeGenClass {
    public function new() {}
}

// @:coreApi  // Not available in all Haxe versions
// class CoreApiClass {
//     public static function test(): Void {}
// }

// Test usage
class Main {
    static function main() {
        // Test what gets generated
        RegularClassWithNative.test();
        RegularClassMethodNative.haxeMethodName();
        LambdaAsRegular.map([1,2,3], x -> x * 2);
        
        // Abstract usage
        LambdaAbstract.fold([1,2,3], (x, acc) -> acc + x, 0);
    }
}