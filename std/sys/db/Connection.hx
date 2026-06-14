package sys.db;

@:build(reflaxe.elixir.macros.SysDbUnsupported.reject("sys.db.Connection"))
interface Connection {
	function request(sql:String):ResultSet;
	function close():Void;
	function escape(value:String):String;
	function quote(value:String):String;
	function addValue(buffer:StringBuf, value:Any):Void;
	function lastInsertId():Int;
	function dbName():String;
	function startTransaction():Void;
	function commit():Void;
	function rollback():Void;
}
