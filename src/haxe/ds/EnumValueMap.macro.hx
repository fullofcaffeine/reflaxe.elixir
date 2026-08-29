package haxe.ds;

/** Host-side enum-value map used when compiler macros execute on eval. */
class EnumValueMap<K:EnumValue, V> extends BalancedTree<K, V> {
	public function new() {
		super();
	}

	override function compare(k1:K, k2:K):Int {
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
