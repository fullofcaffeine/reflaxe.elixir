@:elixirStruct
@:native("Demo.Options")
class Options {
	public var name:String;
	public var count:Int;
	@:native("enabled?") public var enabled:Bool;

	public function new(name:String, count:Int = 0, enabled:Bool = true) {
		this.name = name;
		this.count = count;
		this.enabled = enabled;
	}
}

class Main {
	public static function make():Options {
		return new Options("Ada");
	}
}
