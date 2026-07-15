package phoenix_chat_hx.frontend;

import elixir.ElixirMap;
import elixir.Kernel;
import elixir.types.Term;
import phoenix.Params;

/** Exact server-side event boundary for the project-local React island. */
class PreferenceStudioContract {
	public static inline final EventName = "preference_changed";
	public static inline final NativeEventName = "preference_changed_native";

	public static function decodePayload(params:Term):Null<PreferenceDensity> {
		if (!Kernel.isMap(params)) {
			return null;
		}
		var keys:Array<Term> = ElixirMap.keys(params);
		if (keys.length != 1) {
			return null;
		}
		return PreferenceDensity.fromWire(Params.getString(params, "density"));
	}

	/**
		Normalize Phoenix's closed button carriage without widening the public
		React event. LiveView adds an empty `value` field to button clicks.
	**/
	public static function decodeNativeButtonPayload(params:Term):Null<PreferenceDensity> {
		if (!Kernel.isMap(params)) {
			return null;
		}
		var keys:Array<Term> = ElixirMap.keys(params);
		if (keys.length != 2 || Params.getString(params, "value") != "") {
			return null;
		}
		return PreferenceDensity.fromWire(Params.getString(params, "density"));
	}
}
