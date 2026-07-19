package;

/** Closed semantic input shared by the React boundary and LiveView protocol. */
typedef StatusPanelActionInput = {
	var density:String;
	var enabled:Bool;
	var progress:Float;
	var tags:Array<String>;
	var indexes:Array<Int>;

	@:wire("selected_index")
	var selectedIndex:Int;

	@:optional
	var note:Null<String>;
}

/** One Haxe-owned client-to-LiveView event contract for the fixture island. */
@:liveEventProtocol
enum StatusPanelEvent {
	@:hookEvent("status_panel_action")
	Action(payload:StatusPanelActionInput);

	@:hookEvent
	Ping;
}
