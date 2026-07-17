package;

import phoenix.live_react.LiveReact;
import phoenix.types.Assigns;

typedef StatusCardAssigns = {
	var id:String;
	var title:String;
}

@:native("AppWeb.ReactComponents")
@:component
class ReactComponents {
	@:component
	public static function statusCard(assigns:Assigns<StatusCardAssigns>):String {
		return < LiveReact.react
		id = ${assigns.id} name = "StatusCard"
		title = ${assigns.title} ssr = ${false} / >;
	}
}
