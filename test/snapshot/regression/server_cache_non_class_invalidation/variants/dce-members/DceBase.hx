class DceBase {
	public function new() {}

	// Unused at first, so `-dce full` removes it. DceKid inherits it, and its
	// module gets a `hello` delegator only while it is live.
	public function hello():String
		return "hi";
}
