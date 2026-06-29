import phoenix.live_view.LiveEventProtocol;

@:liveEventProtocol("BadFormEvents")
enum BadFormEvent {
	@:submitEvent("create_todo")
	CreateTodo(title:String);
}

class Main {
	static final manifest = LiveEventProtocol.manifest(BadFormEvent);

	static function main():Void {
		trace(manifest);
	}
}
