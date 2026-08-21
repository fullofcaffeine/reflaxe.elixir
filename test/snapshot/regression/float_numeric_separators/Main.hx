class Main {
	static function main():Void {}

	@:keep
	public static function values():Array<Float> {
		return [12.3_4, 1_2.34, .3_4_5, 1_2e3_4, 1_2.3e4_5, 1_2.3_4f64];
	}
}
