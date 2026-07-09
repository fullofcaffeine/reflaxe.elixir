package sys.db;

@:build(reflaxe.elixir.macros.SysDbUnsupported.reject("sys.db.Mysql"))
class Mysql {
	public static function connect(params:{
		host:String,
		?port:Int,
		user:String,
		pass:String,
		?socket:String,
		?database:String
	}):Connection {
		throw "sys.db.Mysql is not supported on the Elixir target";
	}
}
