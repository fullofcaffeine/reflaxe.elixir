@:access(AccessScope)
class Reader {
	public static function read():Int {
		var captured = PrivateOnly.value;
		var instance = new InstanceScope(17);
		return Anchored.value() + Anchored.anchor() + captured() + AccessScope.value() + instance.value();
	}
}
