package shared.liveview;

import phoenix.live_view.LiveEventProtocolCompanion;

/**
 * Template-origin LiveView events for repeated todo row actions.
 *
 * This RailsHx-inspired example keeps simple local events in direct PhoenixHx
 * branches, but uses a protocol for the repeated toggle button so the event
 * name, `phx-value-id` decode, and handler signature stay in sync.
 */
@:liveEventProtocol
enum TodoEvent {
	@:templateEvent
	ToggleTodo(id:Int);
}

typedef TodoEvents = LiveEventProtocolCompanion<TodoEvent>;
