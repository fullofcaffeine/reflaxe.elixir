package shared.liveview;

import phoenix.live_view.LiveEventProtocolCompanion;

/**
 * Form payload sent by the new-todo form.
 *
 * Phoenix submits the fields under the `todo` root (`todo[title]`,
 * `todo[description]`, ...). The protocol macro reads that map and builds this
 * typed value before TodoLive handles the event.
 */
typedef CreateTodoForm = {
	var title:String;
	@:optional var description:Null<String>;
	@:optional var priority:Null<String>;
	@:optional var dueDate:Null<String>;
	@:optional var tags:Null<String>;
}

/**
 * Shared LiveView events whose payload shape is worth checking.
 *
 * WHAT
 * - Declares payload-bearing template/form events whose Phoenix params should
 *   be decoded into typed handler arguments.
 *
 * WHY
 * - Row actions and the create form cross the HXX template/server boundary.
 *   The generated companion keeps event names and server decoding in sync while
 *   the template remains ordinary Phoenix markup.
 */
@:liveEventProtocol("TodoEvents")
enum TodoEvent {
	@:templateEvent("toggle_todo")
	ToggleTodo(id:Int);

	@:submitEvent("create_todo", "todo")
	CreateTodo(payload:CreateTodoForm);
}

typedef TodoEvents = LiveEventProtocolCompanion<TodoEvent>;
