package;

import elixir.types.Term;
import phoenix.live_react.LiveReact;
import phoenix.types.Assigns;

typedef StatusCardAssigns = {
	var id:String;
	var title:String;
}

/**
 * App-owned typed boundary around the open stock LiveReact component.
 */
@:native("AppWeb.ReactComponents")
@:component
class ReactComponents {
	/** Type-level probe that keeps the extern call ABI in this snapshot. */
	@:keep
	public static function callStock(assigns:Assigns<StatusCardAssigns>):Term {
		return LiveReact.react(assigns);
	}

	@:component
	public static function statusCard(assigns:Assigns<StatusCardAssigns>):String {
		return <div class="react-island-host">
			<LiveReact.react
				id=${assigns.id}
				name="StatusCard"
				title=${assigns.title}
				ssr=${false}
			/>
		</div>;
	}
}
