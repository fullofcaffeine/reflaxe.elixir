import phoenix.live_view.LiveEventProtocol;

typedef BadPayload = {
	var message:String;
	var raw:Dynamic;
}

@:liveEventProtocol("BadHookEvents")
enum BadHookEvent {
	Bad(payload:BadPayload);
}

class Main {
	static final manifest = LiveEventProtocol.manifest(BadHookEvent);

	static function main():Void {}
}
