/** A conditional native method must not become unconditional due to class size. */
@:native("Retention.ConditionalField")
class ConditionalFieldModule {
	@:ifFeature("retention.unused")
	public static function value():Int
		return 7;
}
