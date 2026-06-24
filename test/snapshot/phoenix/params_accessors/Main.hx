import elixir.types.Term;
import phoenix.Params;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition) {
			throw message;
		}
	}

	static function main() {
		var params:Term = untyped __elixir__('%{
          "title" => "Ship it",
          "id" => "42",
          "done" => "true",
          "todo" => %{"id" => 99}
        }');

		assertThat(Params.getString(params, "title") == "Ship it", "getString failed");
		assertThat(Params.getString(params, "missing") == null, "missing getString failed");
		assertThat(Params.getStringDefault(params, "missing", "fallback") == "fallback", "getStringDefault failed");
		assertThat(Params.getInt(params, "id") == 42, "getInt string failed");
		assertThat(Params.getNestedInt(params, "todo", "id") == 99, "getNestedInt failed");
		assertThat(Params.getBool(params, "done") == true, "getBool string failed");
		assertThat(Params.getIntDefault(params, "missing", 7) == 7, "getIntDefault failed");
	}
}
