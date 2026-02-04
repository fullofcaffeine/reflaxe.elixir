package haxe.ds;

/**
 * EnumValueMap (Elixir target) — bootstrap-safe override
 *
 * See `src/haxe/ds/BalancedTree.hx` for a beginner-friendly explanation of why this is dual-mode.
 */
#if macro
class EnumValueMap<K:EnumValue, V> extends BalancedTree<K, V> {
    public function new() {
        super();
    }

    override function compare(k1: K, k2: K): Int {
        return Reflect.compare(k1, k2);
    }

    override public function copy():EnumValueMap<K, V> {
        var copied = new EnumValueMap<K, V>();
        for (kv in this.keyValueIterator()) {
            copied.set(kv.key, kv.value);
        }
        return copied;
    }
}
#else
@:nativeGen
extern class EnumValueMap<K:EnumValue, V> extends BalancedTree<K, V> {
    public function new():Void;
    public function copy():EnumValueMap<K, V>;
}
#end
