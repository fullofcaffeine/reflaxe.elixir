package;

import phoenix.channels.WireCodec;

abstract StatusPanelId(Int) from Int to Int {}

class StatusPanelIdCodec {
	public static function codec():WireCodec<StatusPanelId> {
		// Compile-time fixture only: the LiveReact projector must require an
		// application-owned TypeScript equivalent before this codec can cross.
		return cast null;
	}
}

typedef CustomStatusPanelInput = {
	@:codec(StatusPanelIdCodec.codec())
	var id:StatusPanelId;
}

@:liveEventProtocol
enum CustomStatusPanelEvent {
	@:hookEvent
	Selected(payload:CustomStatusPanelInput);
}
