package;

import phoenix.channels.Payload;

@:liveEventProtocol
enum OpenStatusPanelEvent {
	@:hookEvent
	Forward(payload:Payload);
}
