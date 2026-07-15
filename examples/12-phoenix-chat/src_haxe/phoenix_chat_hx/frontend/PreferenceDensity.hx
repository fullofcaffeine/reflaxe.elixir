package phoenix_chat_hx.frontend;

/** Closed wire vocabulary shared by the native LiveView wrapper and its tests. */
enum abstract PreferenceDensity(String) to String {
	var Calm = "calm";
	var Focused = "focused";
	var Dense = "dense";

	public static function fromWire(value:Null<String>):Null<PreferenceDensity> {
		return switch value {
			case "calm": Calm;
			case "focused": Focused;
			case "dense": Dense;
			case _: null;
		};
	}

	public function label():String {
		return switch this {
			case Calm: "Calm";
			case Focused: "Focused";
			case Dense: "Dense";
			case _: "Unknown";
		};
	}
}
