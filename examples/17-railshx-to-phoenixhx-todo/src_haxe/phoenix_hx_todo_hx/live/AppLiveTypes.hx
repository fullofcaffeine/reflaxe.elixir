package phoenix_hx_todo_hx.live;

typedef TodoItem = {
	var id:Int;
	var title:String;
	var notes:String;
	var owner:String;
	var completed:Bool;
	var row_class:String;
}

typedef TodoStats = {
	var open_count:Int;
	var completed_count:Int;
	var typed_column_count:Int;
}

typedef AppLiveAssigns = {
	authenticated:Bool,
	current_user_name:String,
	current_user_email:String,
	title_input:String,
	notes_input:String,
	todos:Array<TodoItem>,
	next_todo_id:Int,
	status:Null<String>,
	stats:TodoStats,
}
