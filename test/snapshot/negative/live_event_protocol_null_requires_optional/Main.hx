import phoenix.live_view.LiveEventProtocol;

typedef BadPayload = {
	var message:Null<String>;
}

@:liveEventProtocol("BadHookEvents")
enum BadHookEvent {
	Bad(payload:BadPayload);
}

class Main {
	static final manifest = LiveEventProtocol.manifest(BadHookEvent);

	static function main():Void {}
}
