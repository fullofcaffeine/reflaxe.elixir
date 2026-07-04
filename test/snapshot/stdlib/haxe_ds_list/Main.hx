import haxe.ds.List;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition) {
			throw message;
		}
	}

	static function main():Void {
		var values = new List<String>();
		values.add("one");
		values.add("two");
		values.push("zero");

		assertThat(values.length == 3, "length should track add and push");
		assertThat(values.first() == "zero", "first should reflect pushed head");
		assertThat(values.last() == "two", "last should reflect appended tail");
		assertThat(values.toString() == "{zero, one, two}", "toString should preserve order");

		var entries = new Array<String>();
		var keyValueIterator = values.keyValueIterator();
		while (keyValueIterator.hasNext()) {
			var entry = keyValueIterator.next();
			entries.push(entry.key + ":" + entry.value);
		}
		assertThat(entries.join(",") == "0:zero,1:one,2:two", "keyValueIterator should preserve indices");

		assertThat(values.remove("one"), "remove should delete first matching value");
		assertThat(!values.remove("missing"), "remove should report missing values");
		assertThat(values.pop() == "zero", "pop should remove the head");
		assertThat(values.toString() == "{two}", "pop/remove should rebind receiver state");

		var mapped = values.map(function(value) return value + "!");
		assertThat(mapped.toString() == "{two!}", "map should return a new list");

		values.clear();
		assertThat(values.isEmpty(), "clear should empty the list");
	}
}
