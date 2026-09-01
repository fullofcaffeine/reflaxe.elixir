package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.Term;
import elixir.types.Atom;
import elixir.types.Tuple2;
import haxe.extern.EitherType;

/** Native `:file` result tagged with `:ok` or `:error`. */
typedef ErlangFileResult = Tuple2<Atom, Term>;

/** Native read result: either `:eof` or a tagged tuple. */
typedef ErlangFileReadResult = EitherType<ErlangFilePosition, ErlangFileResult>;

/** Native write result: either `:ok` or an error tuple. */
typedef ErlangFileWriteResult = EitherType<Atom, ErlangFileResult>;

/** Typed access to Erlang filesystem error formatting. */
@:native(":file")
extern class ErlangFile {
	/** Construct a typed native position tuple without a runtime helper. */
	public static extern inline function positionAt(origin:ErlangFilePosition, offset:Int):Tuple2<ErlangFilePosition, Int> {
		return {_0: origin, _1: offset};
	}

	/** Read at most `length` bytes from an Erlang IO device. */
	@:native("read")
	public static function read(device:Term, length:Int):ErlangFileReadResult;

	/** Move or query an Erlang IO device position. */
	@:native("position")
	public static function position(device:Term, location:Term):ErlangFileResult;

	/** Write binary data to an Erlang IO device. */
	@:native("write")
	public static function write(device:Term, data:Term):ErlangFileWriteResult;

	@:native("format_error")
	public static function formatError(reason:Term):Array<Int>;
}

/** Closed set of origins accepted by `:file.position/2`. */
enum abstract ErlangFilePosition(Atom) to Atom {
	var Begin = "bof";
	var Current = "cur";
	var End = "eof";
}
#end
