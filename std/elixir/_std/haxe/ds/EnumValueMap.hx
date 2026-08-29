package haxe.ds;

/**
 * EnumValueMap (Elixir target override)
 *
 * Macro/eval compilation uses `haxe/ds/EnumValueMap.macro.hx`.
 */
@:nativeGen
extern class EnumValueMap<K:EnumValue, V> extends BalancedTree<K, V> {
	public function new():Void;
	public function copy():EnumValueMap<K, V>;
}
