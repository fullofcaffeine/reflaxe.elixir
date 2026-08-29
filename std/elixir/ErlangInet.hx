package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.Atom;
import elixir.types.Tuple2;
import elixir.types.Tuple4;
import haxe.extern.EitherType;

/** Native IPv4 tuple used by Erlang networking functions. */
typedef ErlangIPv4Address = Tuple4<Int, Int, Int, Int>;

/** Native host record returned by `:inet.gethostbyaddr/1`. */
typedef ErlangHostEntry = {
	_0:Atom,
	_1:Array<Int>,
	_2:Array<Array<Int>>,
	_3:Atom,
	_4:Int,
	_5:Array<ErlangIPv4Address>
};

/** Tagged IPv4 lookup result. */
typedef ErlangInetAddressResult = Tuple2<Atom, EitherType<ErlangIPv4Address, Atom>>;

/** Tagged host-name lookup result. */
typedef ErlangInetNameResult = Tuple2<Atom, EitherType<Array<Int>, Atom>>;

/** Tagged reverse-DNS lookup result. */
typedef ErlangInetHostResult = Tuple2<Atom, EitherType<ErlangHostEntry, Atom>>;

/** Typed access to the Erlang IPv4 name and address functions. */
@:native(":inet")
extern class ErlangInet {
	@:native("getaddr")
	public static function getAddress(name:Array<Int>, family:ErlangInetFamily):ErlangInetAddressResult;

	@:native("gethostname")
	public static function getHostname():ErlangInetNameResult;

	@:native("gethostbyaddr")
	public static function getHostByAddress(address:ErlangIPv4Address):ErlangInetHostResult;
}

/** Closed set of address families used by the target standard library. */
enum abstract ErlangInetFamily(Atom) to Atom {
	var IPv4 = "inet";
}
#end
