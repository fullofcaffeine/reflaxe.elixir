import haxe.format.JsonParser;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Void {
		var obj:Dynamic = JsonParser.parse("{\"name\":\"Ada\",\"count\":3,\"items\":[1,true,null],\"escaped\":\"line\\nnext\"}");

		assertThat(Reflect.field(obj, "name") == "Ada", "json object string field failed");
		assertThat(Reflect.field(obj, "count") == 3, "json object int field failed");
		assertThat(Reflect.field(obj, "escaped") == "line\nnext", "json escaped string failed");

		var items:Array<Dynamic> = cast Reflect.field(obj, "items");
		assertThat(items.length == 3, "json array length failed");
		assertThat(items[0] == 1, "json array int failed");
		assertThat(items[1] == true, "json array bool failed");
		assertThat(items[2] == null, "json array null failed");

		assertThat(JsonParser.parse("\"ok\"") == "ok", "top-level json string failed");
		assertThat(JsonParser.parse("null") == null, "top-level json null failed");

		try {
			JsonParser.parse("{\"unterminated\":");
			assertThat(false, "invalid json should raise");
		} catch (error:Dynamic) {
			assertThat(error != null, "invalid json should expose an error");
		}
	}
}
