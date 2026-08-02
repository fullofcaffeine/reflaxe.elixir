package phoenixhx_live_react_hx.components.live_react;

import phoenix.live_react.LiveReact;
import phoenix.types.Assigns;

private typedef SignalConsoleAssigns = {
	var id:String;
	var title:String;
	var pulse_count:Int;
}

/**
 * Hand-owned typed Phoenix boundary for the fixed SignalConsole React island.
 *
 * Keep the component name and SSR posture static. Extend this closed assigns
 * type alongside the trusted TypeScript boundary when adding public props.
 */
@:native("PhoenixhxLiveReactWeb.ReactIslands.SignalConsole")
@:component
class SignalConsoleIsland {
	@:component
	public static function render(assigns:Assigns<SignalConsoleAssigns>):String {
		return <div class="react-island-host">
			<LiveReact.react
				id=${assigns.id}
				name="SignalConsole"
				title=${assigns.title}
				pulseCount=${assigns.pulse_count}
				ssr=${false}
			/>
		</div>;
	}
}
