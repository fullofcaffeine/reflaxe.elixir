/**
 * A class that shares its source file with an enum, a typedef and an
 * abstract. The class is first, so an edit that adds lines to it moves the
 * other declarations down in the file.
 */
class CacheMixed {
	public static function describe(kind:CacheMixedKind):String {
		return switch (kind) {
			case Plain:
				final text = "mixed-class-edit";
				text;
			case Marked(label): label;
		};
	}

	public static function record():CacheMixedRecord {
		return {label: "record"};
	}
}

// A comment between the class and the enum. No declaration changes.

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
/* A block comment after the last declaration. */
// A line comment at the end of the file.
