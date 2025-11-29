package server.schemas;

import ecto.Changeset;

typedef TodoParams = {
	?title: String,
	?description: String,
	?completed: Bool,
	?priority: String,
	?dueDate: Date,
	?tags: Array<String>,
	?userId: Int
}

@:native("TodoApp.Todo")
extern class Todo {
	@:field public var id:Int;
	@:field public var title:String;
	@:field public var description:String;
	@:field public var completed:Bool;
	@:field public var priority:String;
	@:field public var dueDate:Null<Date>;
	@:field public var tags:Array<String>;
	@:field public var userId:Int;

	public function new():Void;

	public static function changeset(todo:Todo, params:TodoParams):Changeset<Todo, TodoParams>;
	public static function toggleCompleted(todo:Todo):Changeset<Todo, TodoParams>;
	public static function updatePriority(todo:Todo, priority:String):Changeset<Todo, TodoParams>;
	public static function addTag(todo:Todo, tag:String):Changeset<Todo, TodoParams>;
}
