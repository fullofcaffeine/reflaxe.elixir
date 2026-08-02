package phoenixhx_live_react_hx.live;

import phoenix.live_view.LiveEventProtocolCompanion;

/** The closed payload sent by either SignalConsole control surface. */
typedef SignalPulseInput = {
	var channel:String;
}

/**
 * One shared event contract for the React control and its native LiveView fallback.
 *
 * The generated TypeScript adapter validates the browser payload before calling
 * stock LiveReact's `pushEvent`; the generated LiveView dispatcher validates it
 * again before invoking the Haxe handler below.
 */
@:liveEventProtocol
enum SignalConsoleEvent {
	@:hookEvent("signal_pulse")
	Pulse(payload:SignalPulseInput);
}

typedef SignalConsoleEvents = LiveEventProtocolCompanion<SignalConsoleEvent>;
