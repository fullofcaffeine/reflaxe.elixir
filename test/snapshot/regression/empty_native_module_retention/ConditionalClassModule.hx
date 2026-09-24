/** A class-level condition must also override implicit native module retention. */
@:native("Retention.ConditionalClass")
@:ifFeature("retention.unused")
class ConditionalClassModule {
	public static function value():Int
		return 11;
}
