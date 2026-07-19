package shared.liveview;

import phoenix.live_view.LiveEventProtocolCompanion;

/** Closed semantic payload sent by the Haxe-authored React insights island. */
typedef TodoInsightsFilterInput = {
	var filter:String;
}

/**
 * Client-to-LiveView events owned by the optional TodoInsights island.
 *
 * The wire payload intentionally stays on the Live Event Protocol's supported
 * built-in surface. The trusted Haxe/Genes boundary narrows `filter` to the
 * three admitted values before this event can be pushed.
 */
@:liveEventProtocol
enum TodoInsightsEvent {
	@:hookEvent("todo_insights_filter")
	SetFilter(payload:TodoInsightsFilterInput);
}

typedef TodoInsightsEvents = LiveEventProtocolCompanion<TodoInsightsEvent>;
