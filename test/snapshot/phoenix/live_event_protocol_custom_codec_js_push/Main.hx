import phoenix.channels.Payload;
import phoenix.channels.WirePayload;
import phoenix.live_view.HookContext;
import phoenix.live_view.LiveEventProtocolCompanion;

typedef ResourceSelectedPayload = {
	@:codec(ResourceIdCodec.codec())
	var resourceId:ResourceId;

	var source:String;
}

@:liveEventProtocol("ResourceHookEvents")
enum ResourceHookEvent {
	@:event("resource_selected")
	ResourceSelected(payload:ResourceSelectedPayload);

	Ping;
}

typedef ResourceHookEvents = LiveEventProtocolCompanion<ResourceHookEvent>;

class Main {
	static function main():Void {
		var pushed:Array<String> = [];
		var hook:HookContext = cast {
			el: null,
			pushEvent: function(event:String, payload:Payload):Void {
				var nested = WirePayload.getPayload(payload, "resource_id");
				var id = nested == null ? null : WirePayload.getInt(nested, "value");
				pushed.push(event + ":" + id + ":" + WirePayload.getString(payload, "source"));
			}
		};

		ResourceHookEvents.pushResourceSelected(hook, {resourceId: new ResourceId(42), source: "row"});
		ResourceHookEvents.push(hook, ResourceSelected({resourceId: new ResourceId(43), source: "keyboard"}));
		ResourceHookEvents.pushPing(hook);

		if (pushed.length != 3) {
			throw "expected three pushed events";
		}
	}
}
