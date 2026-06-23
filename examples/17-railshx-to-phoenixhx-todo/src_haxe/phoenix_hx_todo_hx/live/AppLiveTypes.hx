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

typedef ChatMessageItem = {
	var id:Int;
	var body:String;
	var owner:String;
	var row_class:String;
}

typedef AppLiveAssigns = {
	authenticated:Bool,
	current_user_id:Null<Int>,
	current_user_name:String,
	current_user_email:String,
	csrf_token:String,
	title_input:String,
	notes_input:String,
	todos:Array<TodoItem>,
	chat_input:String,
	chat_messages:Array<ChatMessageItem>,
	status:Null<String>,
	stats:TodoStats,
}
