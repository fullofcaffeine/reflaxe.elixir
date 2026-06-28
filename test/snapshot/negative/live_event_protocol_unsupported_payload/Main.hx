import phoenix.live_view.LiveEventProtocol;

@:liveEventProtocol("BadHookEvents")
enum BadHookEvent {
	Bad(value:Dynamic);
}

class Main {
	static final manifest = LiveEventProtocol.manifest(BadHookEvent);

	static function main():Void {
		trace(manifest);
	}
}
