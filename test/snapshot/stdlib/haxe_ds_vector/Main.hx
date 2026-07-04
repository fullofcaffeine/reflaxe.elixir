import haxe.ds.Vector;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition) {
			throw message;
		}
	}

	static function main():Void {
		var values = new Vector<Int>(4, 0);
		values[0] = 99;
		values[1] = 101;
		values[2] = -12;
		values[3] = 0;
		values.sort(Reflect.compare);

		assertThat(values.join(",") == "-12,0,99,101", "sort should use numeric Reflect.compare ordering");

		var copied = values.copy();
		values[0] = 7;
		assertThat(copied[0] == -12, "copy should preserve the old backing snapshot");

		var mapped = values.map(function(value) return "v:" + value);
		assertThat(mapped.join("|") == "v:7|v:0|v:99|v:101", "map should return a new vector");

		var dest = new Vector<Int>(5, -1);
		Vector.blit(values, 0, dest, 1, 3);
		assertThat(dest.join(",") == "-1,7,0,99,-1", "blit should copy from the source snapshot");

		var arr = dest.toArray();
		dest[1] = 8;
		assertThat(arr[1] == 7, "toArray should preserve a snapshot");

		var alias = Vector.fromData(dest.toData());
		alias[2] = 42;
		assertThat(dest[2] == 42, "fromData should share backing state");

		var sum = 0;
		for (value in dest) {
			sum += value;
		}
		assertThat(sum == 147, "iterator should read the current backing state");
	}
}
