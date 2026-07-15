package phoenix_chat_hx.components;

import phoenix.types.Assigns;

typedef PreferenceStudioAssigns = {
	var id:String;
	var title:String;
	var density:String;
}

/**
	Phoenix-owned wrapper around one fixed stock live_react component.

	The component name and SSR posture cannot arrive from request data. Public
	props are closed by this assigns type and validated again at the TypeScript
	boundary. Slots, uploads, streams, and raw bridge capabilities are absent.
**/
@:native("PhoenixChatWeb.ReactComponents")
@:component
class ReactComponents {
	@:component
	public static function preferenceStudio(assigns:Assigns<PreferenceStudioAssigns>):String {
		return <div class="react-island-host">
			<LiveReact.react
				id=${assigns.id}
				name="PreferenceStudio"
				title=${assigns.title}
				density=${assigns.density}
				ssr=${false}
			/>
		</div>;
	}
}
