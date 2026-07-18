package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.Atom;

/** Read-only typed view of Elixir's native `%File.Stat{}` value. */
@:elixirStruct
@:native("File.Stat")
extern class FileStat {
	public var type:Atom;
	public var mode:Int;
}
#end
