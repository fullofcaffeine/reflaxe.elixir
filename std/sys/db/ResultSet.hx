package sys.db;

@:build(reflaxe.elixir.macros.SysDbUnsupported.reject("sys.db.ResultSet"))
interface ResultSet {
	var length(get, null):Int;
	var nfields(get, null):Int;

	function hasNext():Bool;
	function next():Any;
	function results():List<Any>;
	function getResult(index:Int):String;
	function getIntResult(index:Int):Int;
	function getFloatResult(index:Int):Float;
	function getFieldsNames():Null<Array<String>>;
}
