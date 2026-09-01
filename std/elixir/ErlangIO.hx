package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.Atom;
import elixir.types.Term;
import elixir.types.Tuple3;
import elixir.types.Tuple4;

/** A native request that reads raw Latin-1 bytes from an IO device. */
typedef ErlangIOByteReadRequest = Tuple4<Atom, Atom, String, Int>;

/** A native request that reads one Unicode line from an IO device. */
typedef ErlangIOLineReadRequest = Tuple3<Atom, Atom, String>;

/** Typed access to the Erlang `:io` request boundary. */
@:native(":io")
extern class ErlangIO {
	/** Build a byte-read request with a string prompt for all IO servers. */
	public static extern inline function byteReadRequest(length:Int):ErlangIOByteReadRequest {
		return {
			_0: "get_chars",
			_1: "latin1",
			_2: "",
			_3: length
		};
	}

	/** Build a line-read request with a string prompt for all IO servers. */
	public static extern inline function lineReadRequest():ErlangIOLineReadRequest {
		return {_0: "get_line", _1: "unicode", _2: ""};
	}

	/** Send one synchronous request to an IO device. */
	@:native("request")
	public static function request(device:Term, request:Term):Term;
}
#end
