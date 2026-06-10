package;

import haxe.ds.ObjectMap;

class Key {
	public final name:String;

	public function new(name:String) {
		this.name = name;
	}
}

class Main {
	public static function main():Void {
		// Negative test: ObjectMap requires object-identity key semantics.
		// The Elixir target must reject this instead of lowering it to a structural `%{}` map.
		var map = new ObjectMap<Key, String>();
		map.set(new Key("same"), "left");
		map.set(new Key("same"), "right");
	}
}
