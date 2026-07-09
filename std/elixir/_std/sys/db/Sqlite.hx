package sys.db;

@:build(reflaxe.elixir.macros.SysDbUnsupported.reject("sys.db.Sqlite"))
class Sqlite {
	public static function open(file:String):Connection {
		throw "sys.db.Sqlite is not supported on the Elixir target";
	}
}
