import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;
import phoenix.channels.EncodedEvent;
import phoenix.channels.Payload;
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

typedef ResourceAssigns = {
	var selectedResourceId:Int;
}

@:liveview
@:liveEvents(ResourceHookEvent, "dispatchResourceHookEvent")
class ProfileLive {
	public static function encodeSelected(resourceId:ResourceId, source:String):EncodedEvent {
		var payload:ResourceSelectedPayload = {resourceId: resourceId, source: source};
		return ResourceHookEvents.encode(ResourceSelected(payload));
	}

	public static function decodeSelected(payload:Payload):Null<ResourceHookEvent> {
		return ResourceHookEvents.decode(ResourceHookEvents.ResourceSelectedEvent, payload);
	}

	public static function handleEvent(event:String, params:Term, socket:Socket<ResourceAssigns>):HandleEventResult<ResourceAssigns> {
		var hookResult = dispatchResourceHookEvent(event, params, socket);
		if (hookResult != null) {
			return hookResult;
		}

		return NoReply(socket);
	}

	static function handleResourceSelected(payload:ResourceSelectedPayload, socket:Socket<ResourceAssigns>):HandleEventResult<ResourceAssigns> {
		return NoReply(LiveView.assign(socket, "selected_resource_id", payload.resourceId));
	}

	static function handlePing(socket:Socket<ResourceAssigns>):HandleEventResult<ResourceAssigns> {
		return NoReply(socket);
	}
}
