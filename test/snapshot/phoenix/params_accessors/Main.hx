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

		var atomParams:Term = untyped __elixir__('%{
          title: "Atom title",
          id: 13,
          done: false,
          todo: %{id: "11"}
        }');

		assertThat(Params.getString(atomParams, "title") == "Atom title", "atom getString failed");
		assertThat(Params.getInt(atomParams, "id") == 13, "atom getInt failed");
		assertThat(Params.getNestedInt(atomParams, "todo", "id") == 11, "atom getNestedInt failed");
		assertThat(Params.getBool(atomParams, "done") == false, "atom getBool failed");
		assertThat(Params.get(atomParams, "params_accessors_missing_atom") == null, "missing atom fallback failed");

		var mixedParams:Term = untyped __elixir__('%{"title" => nil, title: "Atom title"}');
		assertThat(Params.get(mixedParams, "title") == null, "string-key nil should win over atom fallback");
	}
}
