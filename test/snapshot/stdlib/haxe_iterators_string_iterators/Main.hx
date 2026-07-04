import haxe.iterators.StringIterator;
import haxe.iterators.StringKeyValueIterator;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition) {
			throw message;
		}
	}

	static function main():Void {
		var iterator = new StringIterator("aé中");
		var codes = new Array<Int>();
		while (iterator.hasNext()) {
			codes.push(iterator.next());
		}
		assertThat(codes.join(",") == "97,233,20013", "StringIterator should return codepoints");

		var keyValueIterator = new StringKeyValueIterator("aé中");
		var entries = new Array<String>();
		while (keyValueIterator.hasNext()) {
			var entry = keyValueIterator.next();
			entries.push(entry.key + ":" + entry.value);
		}
		assertThat(entries.join(",") == "0:97,1:233,2:20013", "StringKeyValueIterator should return character indices and codepoints");
	}
}
