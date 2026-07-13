class Main {
	public static function main() {
		var oneBased = oneBasedTuple();
		if (oneBased._1 != "one" || oneBased._2 != 2)
			throw "one-based tuple access failed";
		var matched = switch (oneBased) {
			case {_1: "one", _2: value}: value;
			default: -1;
		};
		if (matched != 2)
			throw "one-based tuple pattern failed";

		var zeroBased = zeroBasedTuple();
		if (zeroBased._0 != "zero" || zeroBased._1 != 1)
			throw "zero-based tuple access failed";

		var nested = nestedTuple();
		if (nested._1._1 != "nested" || nested._1._2 != 7 || nested._2 != "outer")
			throw "nested tuple access failed";

		var mutable = mutableTuple();
		mutable._2 = 9;
		mutable._1 += 4;
		if (mutable._1 != 5 || mutable._2 != 9)
			throw "one-based tuple update failed";

		zeroBased._1 = 8;
		if (zeroBased._0 != "zero" || zeroBased._1 != 8)
			throw "zero-based tuple update failed";

		var mixed = mixedObject();
		mixed._1 = "updated";
		if (mixed._1 != "updated" || mixed.label != "mixed")
			throw "mixed anonymous object must remain a map";

		var gapped = gappedObject();
		if (gapped._1 != "map" || gapped._3 != 3)
			throw "gapped anonymous object must remain a map";
	}

	static function oneBasedTuple():{_1:String, _2:Int} {
		return {_1: "one", _2: 2};
	}

	static function zeroBasedTuple():{_0:String, _1:Int} {
		return {_0: "zero", _1: 1};
	}

	static function nestedTuple():{_1:{_1:String, _2:Int}, _2:String} {
		return {_1: {_1: "nested", _2: 7}, _2: "outer"};
	}

	static function mutableTuple():{_1:Int, _2:Int} {
		return {_1: 1, _2: 2};
	}

	static function mixedObject():{_1:String, label:String} {
		return {_1: "map", label: "mixed"};
	}

	static function gappedObject():{_1:String, _3:Int} {
		return {_1: "map", _3: 3};
	}
}
