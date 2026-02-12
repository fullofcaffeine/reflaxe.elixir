import elixir.types.Term;
import phoenix.channels.WirePayload;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition) {
			throw message;
		}
	}

	static function main() {
		var payload:Term = WirePayload.empty();

		payload = WirePayload.putString(payload, "s", "hello");
		payload = WirePayload.putInt(payload, "i", 123);
		payload = WirePayload.putBool(payload, "b", true);
		payload = WirePayload.putFloat(payload, "f", 1.25);

		assertThat(WirePayload.getString(payload, "s") == "hello", "getString failed");
		assertThat(WirePayload.getInt(payload, "i") == 123, "getInt failed");
		assertThat(WirePayload.getBool(payload, "b") == true, "getBool failed");
		assertThat(WirePayload.getFloat(payload, "f") == 1.25, "getFloat failed");

		// Elixir-side enhancements: parse ints from numeric strings and integral floats.
		payload = WirePayload.putString(payload, "i_str", "456");
		assertThat(WirePayload.getInt(payload, "i_str") == 456, "getInt (string) failed");

		payload = WirePayload.putFloat(payload, "i_float", 789.0);
		assertThat(WirePayload.getInt(payload, "i_float") == 789, "getInt (integral float) failed");

		// Nested payload access.
		var nested:Term = WirePayload.empty();
		nested = WirePayload.putString(nested, "n", "x");
		payload = WirePayload.putPayload(payload, "nested", nested);

		var gotNested = WirePayload.getPayload(payload, "nested");
		assertThat(gotNested != null, "getPayload failed");
		assertThat(WirePayload.getString(gotNested, "n") == "x", "nested getString failed");

		// Arrays: allow atom/binary string arrays and parse int arrays from common representations.
		var saTerms:Array<Term> = [untyped __elixir__(":ok"), cast "hi"];
		payload = WirePayload.putPayload(payload, "sa", cast saTerms);

		var sa = WirePayload.getStringArray(payload, "sa");
		assertThat(sa != null, "getStringArray failed");
		assertThat(sa[0] == "ok" && sa[1] == "hi", "getStringArray values failed");

		payload = WirePayload.putPayload(payload, "ia", untyped __elixir__('[1, \"2\", 3.0]'));
		var ia = WirePayload.getIntArray(payload, "ia");
		assertThat(ia != null, "getIntArray failed");
		assertThat(ia[0] == 1 && ia[1] == 2 && ia[2] == 3, "getIntArray values failed");
	}
}
