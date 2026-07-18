import elixir.ElixirException;
import elixir.Kernel;
import elixir.types.Atom;
import elixir.types.NativeException;
import elixir.types.Term;

class Main {
	static inline final OK:Atom = "ok";
	static inline final ERROR:Atom = "error";

	public static function safely(fun:Void->Void):Term {
		try {
			fun();
			return OK;
		} catch (error:NativeException) {
			return {_0: ERROR, _1: ElixirException.message(error)};
		}
	}

	public static function fail():Term {
		return safely(function():Void Kernel.raise("boom"));
	}
}
