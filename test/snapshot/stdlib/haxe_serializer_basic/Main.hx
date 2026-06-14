package;

import haxe.Serializer;
import haxe.Unserializer;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Void {
		var primitiveWire = Serializer.run(["alpha", 42, true, null]);
		var primitiveValue:Array<Dynamic> = Unserializer.run(primitiveWire);

		assertThat(primitiveValue[0] == "alpha", "string roundtrip failed");
		assertThat(primitiveValue[1] == 42, "int roundtrip failed");
		assertThat(primitiveValue[2] == true, "bool roundtrip failed");
		assertThat(primitiveValue[3] == null, "null roundtrip failed");

		var stringMap = new haxe.ds.StringMap<Int>();
		stringMap.set("one", 1);
		stringMap.set("two", 2);

		var mapWire = Serializer.run(stringMap);
		var mapValue:haxe.ds.StringMap<Int> = Unserializer.run(mapWire);

		assertThat(mapValue.get("one") == 1, "string map one failed");
		assertThat(mapValue.get("two") == 2, "string map two failed");

		var serializer = new Serializer();
		serializer.serialize("prefix");
		serializer.serialize(7);
		var instanceWire = serializer.toString();
		assertThat(instanceWire == "y6:prefixi7", "instance serializer buffer failed");

		trace(primitiveWire);
		trace(mapWire);
		trace(instanceWire);
	}
}
