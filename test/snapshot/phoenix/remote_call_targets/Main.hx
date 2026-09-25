import elixir.types.Term;
import elixir.types.TermDecoder;
import elixir.Atom as NativeAtom;
import plug.Conn;

class Main {
	static function main() {}
}

@:keep @:controller @:native("ProbeAppWeb.ProbeController")
class ProbeController {
	public static function halted(conn:Conn<Term>):Bool
		return conn.isHalted();

	public static function helper(value:Int):Int
		return OrdinaryHelper.assign(value, 4, 7);

	public static function decode(value:Term):Term
		return switch TermDecoder.fetchAtomKey(value, NativeAtom.fromString("fixed")) {
			case Ok(field): field;
			case Error(_): null;
		};
}

@:keep @:channel @:native("ProbeAppWeb.ProbeChannel")
class ProbeChannel {
	public static function join(_topic:String, _payload:Term, socket:Term):phoenix.channels.JoinResult<Term>
		return Ok(socket);

	public static function direct(socket:Term):Term
		return NativeSocket.assign(socket, NativeAtom.fromString("fixed"), "plain");

	public static function nested(socket:Term, admission:Admission):Term {
		return switch admission {
			case Denied: socket;
			case Granted(reference):
				socket = NativeSocket.assign(socket, NativeAtom.fromString("fixed"), reference.text());
				socket = NativeSocket.assign(socket, NativeAtom.fromString("other"), "second");
				socket;
		};
	}
}

/** Same method name as a framework API must retain its authored target. */
@:keep
class OrdinaryHelper {
	public static function assign(value:Int, scale:Int, offset:Int):Int
		return value * scale + offset;
}

/** The plain module is a control for annotation-dependent rewriting. */
@:keep
class PlainRemoteCalls {
	public static function nested(socket:Term, admission:Admission):Term {
		return switch admission {
			case Denied: socket;
			case Granted(reference): NativeSocket.assign(socket, NativeAtom.fromString("fixed"), reference.text());
		};
	}
}

enum Admission {
	Denied;
	Granted(reference:Reference);
}

abstract Reference(String) from String {
	public inline function text():String
		return this;
}

/** Exact Phoenix public API; runtime validation uses the real dependency. */
@:native("Phoenix.Socket") private extern class NativeSocket {
	public static function assign(socket:Term, key:elixir.types.Atom, value:String):Term;
}
