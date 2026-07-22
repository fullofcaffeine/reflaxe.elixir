class Main {
	static function main():Void {}

	public static function currentStatus():CacheStatus {
		return Ready;
	}

	public static function combine(payload:CachePayload) {
		return payload.value + payload.value;
	}

	public static function render(code:CacheCode):Int {
		return code.render();
	}

	public static function moduleLabel():String {
		return CacheLegacy.label();
	}
}
