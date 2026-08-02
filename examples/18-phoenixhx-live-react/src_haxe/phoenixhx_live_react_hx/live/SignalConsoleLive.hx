package phoenixhx_live_react_hx.live;

import elixir.ElixirInteger;
import elixir.ElixirString;
import phoenix.Phoenix.EventParams;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountParams;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Session;
import phoenix.Phoenix.Socket;
import phoenixhx_live_react_hx.live.SignalConsoleEvents.SignalConsoleEvent;
import phoenixhx_live_react_hx.live.SignalConsoleEvents.SignalConsoleEvents;
import phoenixhx_live_react_hx.live.SignalConsoleEvents.SignalPulseInput;

private typedef SignalConsoleAssigns = {
	var pulse_count:Int;
	var channel:String;
	var status:String;
}

/**
 * Minimal real LiveView host for the independent plain-JavaScript LiveReact example.
 *
 * React and the native button send the same typed event. Phoenix owns the
 * authoritative count, so browser QA proves the event crossed the real runtime
 * boundary instead of merely changing local React state.
 */
@:native("PhoenixhxLiveReactWeb.SignalConsoleLive")
@:liveview
@:liveEvents(SignalConsoleEvent, dispatchSignalConsoleEvent)
class SignalConsoleLive {
	public static function mount(_params:MountParams, _session:Session, socket:Socket<SignalConsoleAssigns>):MountResult<SignalConsoleAssigns> {
		return Ok(socket.assign({
			pulse_count: 0,
			channel: "ALPHA",
			status: "Waiting for a signal."
		}));
	}

	public static function handleEvent(event:String, params:EventParams, socket:Socket<SignalConsoleAssigns>):HandleEventResult<SignalConsoleAssigns> {
		var typedResult = dispatchSignalConsoleEvent(event, params, socket);
		return typedResult != null ? typedResult : NoReply(socket);
	}

	static function handlePulse(payload:SignalPulseInput, socket:Socket<SignalConsoleAssigns>):HandleEventResult<SignalConsoleAssigns> {
		var channel = normalizeChannel(payload.channel);
		var count = socket.assigns.pulse_count + 1;
		return NoReply(socket.assign({pulse_count: count,
			channel: channel,
			status: "Server received "
			+ channel
			+ " pulse "
			+ ElixirString.padLeadingWith(ElixirInteger.toString(count), 2, "0")
			+ "."}));
	}

	static function normalizeChannel(candidate:String):String {
		return switch (candidate) {
			case "ALPHA" | "BETA" | "GAMMA": candidate;
			case _: "ALPHA";
		};
	}

	public static function render(assigns:SignalConsoleAssigns):String {
		return <main class="integration-shell">
			<header class="integration-nav">
				<a href="/" class="integration-mark" aria-label="PhoenixHx LiveReact example home">PHX<span>×</span>HX</a>
				<p>Integration specimen 018</p>
				<a href="https://github.com/fullofcaffeine/reflaxe.elixir" rel="noreferrer">Source ↗</a>
			</header>

			<section class="integration-hero">
				<div class="integration-copy">
					<p class="integration-kicker">Haxe → Elixir · TypeScript · React</p>
					<h1>One typed server.<br/><em>A familiar browser.</em></h1>
					<p class="integration-lede">
						Phoenix renders the host and handles a typed event. Plain TypeScript owns the
						React island, showing that LiveReact does not require a Haxe browser compiler.
					</p>

					<ol class="integration-route" aria-label="Application compilation route">
						<li><span>01</span><b>Haxe server</b><small>Reflaxe.Elixir</small></li>
						<li><span>02</span><b>Phoenix host</b><small>BEAM runtime</small></li>
						<li><span>03</span><b>TypeScript</b><small>Vite</small></li>
						<li><span>04</span><b>React island</b><small>LiveReact</small></li>
					</ol>
				</div>

				<div class="integration-demo">
					<div class="integration-demo__label">
						<span>Interactive proof</span>
						<span>Client only / SSR off</span>
					</div>
					<PhoenixhxLiveReactWeb.ReactIslands.SignalConsole.render
						id="signal-console"
						title="Signal console"
						pulse_count=${assigns.pulse_count}
					/>

					<p class="signal-console-server-status" role="status" data-testid="server-status">${assigns.status}</p>
					<details class="signal-console-fallback" data-testid="native-fallback">
						<summary>Native LiveView fallback</summary>
						<p>This button sends the same typed event without React.</p>
						<button
							type="button"
							phx-click=${SignalConsoleEvents.PulseEvent}
							phx-value-channel=${assigns.channel}
							data-testid="native-transmit-pulse"
						>Transmit ${assigns.channel} pulse</button>
					</details>
				</div>
			</section>

			<footer class="integration-footer">
				<p><span aria-hidden="true">●</span> Static registry · closed props · stock LiveReact runtime</p>
				<p>Open the README for the exact local workflow and ownership map.</p>
			</footer>
		</main>;
	}
}
