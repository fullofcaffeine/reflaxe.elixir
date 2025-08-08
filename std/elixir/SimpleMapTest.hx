package elixir;

#if (macro || reflaxe_runtime)

/**
 * Simple Map extern for testing
 */
extern class SimpleMapTest {
    
    @:native("Enum.map")
    public static function enumMap<T, U>(enumerable: Array<T>, func: T -> U): Array<U>;
    
    public static function testFunction(): Int;
}

#end