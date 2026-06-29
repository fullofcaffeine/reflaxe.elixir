package shared.liveview;

import phoenix.live_view.LiveEventProtocolCompanion;

/**
 * Shared LiveView template events for repeated todo row actions.
 *
 * WHAT
 * - Declares payload-bearing template events whose `phx-value-*` params should
 *   be decoded into typed handler arguments.
 *
 * WHY
 * - Row actions appear in repeated markup and cross the HXX template/server
 *   boundary. The generated companion keeps event names and server decoding in
 *   sync while the template remains ordinary Phoenix markup.
 */
@:liveEventProtocol("TodoEvents")
enum TodoEvent {
	@:templateEvent("toggle_todo")
	ToggleTodo(id:Int);
}

typedef TodoEvents = LiveEventProtocolCompanion<TodoEvent>;
