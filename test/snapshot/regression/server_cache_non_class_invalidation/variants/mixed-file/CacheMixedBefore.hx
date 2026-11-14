/**
 * A class that shares its source file with an enum, a typedef and an
 * abstract. The class is first, so an edit that adds lines to it moves the
 * other declarations down in the file.
 */
class CacheMixed {
	public static function describe(kind:CacheMixedKind):String {
		return switch (kind) {
			case Plain: "mixed-before";
			case Marked(label): label;
		};
	}

	public static function record():CacheMixedRecord {
		return {label: "record"};
	}
}

enum CacheMixedKind {
	Plain;
	Marked(label:String);
}

typedef CacheMixedRecord = {
	final label:String;
}

abstract CacheMixedCode(Int) from Int to Int {
	public function doubled():Int {
		return this * 2;
	}
}
