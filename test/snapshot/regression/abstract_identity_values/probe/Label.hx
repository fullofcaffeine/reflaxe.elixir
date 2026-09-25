package probe;

/** Ordinary inline constructors must keep their value in conditional factories. */
abstract Label(String) {
	private inline function new(value:String)
		this = value;

	public static function parse(value:String):Null<Label> {
		if (value == "")
			return null;
		return new Label(value);
	}

	public static function identity(value:String):Label {
		return new Label(value);
	}

	public static function choose(first:String, second:String, useFirst:Bool):Label {
		return useFirst ? new Label(first) : new Label(second);
	}

	public static function fromCode(code:Int, value:String):Null<Label> {
		return switch (code) {
			case 1: new Label(value);
			case 2: new Label("fixed");
			default: null;
		};
	}

	public inline function text():String
		return this;
}
