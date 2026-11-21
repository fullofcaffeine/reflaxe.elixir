class DeadLive {
	public static function live():Int
		return 1;

	// Unused, so `-dce full` removes it. It still makes Haxe type DeadTarget,
	// so DeadTarget stays in the module list that Reflaxe gets (Reflaxe takes
	// that list before dead-code elimination runs).
	public static function viaDead():Int
		return DeadTarget.m();
}
