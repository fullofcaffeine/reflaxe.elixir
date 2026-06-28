import phoenix.live_view.LiveEventProtocol;

abstract TodoId(Int) from Int to Int {}

typedef BadPayload = {
	@:codec
	var todoId:TodoId;
}

@:liveEventProtocol("BadHookEvents")
enum BadHookEvent {
	Bad(payload:BadPayload);
}

class Main {
	static final manifest = LiveEventProtocol.manifest(BadHookEvent);

	static function main():Void {}
}
