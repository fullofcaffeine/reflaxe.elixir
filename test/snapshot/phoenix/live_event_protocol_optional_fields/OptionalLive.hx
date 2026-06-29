import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;
import phoenix.channels.Payload;
import phoenix.live_view.LiveEventProtocolCompanion;

typedef OptionalAssigns = {
	var summary:String;
}

typedef ProfileForm = {
	var name:String;
	@:optional var bio:Null<String>;
}

@:liveEventProtocol("OptionalEvents")
enum OptionalEvent {
	@:templateEvent("search")
	Search(?query:String);

	@:submitEvent("save_profile", "profile")
	SaveProfile(payload:ProfileForm);
}

typedef OptionalEvents = LiveEventProtocolCompanion<OptionalEvent>;

@:liveview
@:liveEvents(OptionalEvent, "dispatchOptionalEvent")
class OptionalLive {
	public static function render(assigns:OptionalAssigns):String {
		return <section>
			<button phx-click=${OptionalEvents.SearchEvent}>Search</button>
			<form phx-submit=${OptionalEvents.SaveProfileEvent}>
				<input type="text" name="profile[name]" value=${assigns.summary} />
			</form>
		</section>;
	}

	public static function decodeSearch(payload:Payload):Null<OptionalEvent> {
		return OptionalEvents.decode(OptionalEvents.SearchEvent, payload);
	}

	public static function handleEvent(event:String, params:Term, socket:Socket<OptionalAssigns>):HandleEventResult<OptionalAssigns> {
		var handled = dispatchOptionalEvent(event, params, socket);
		if (handled != null) {
			return handled;
		}

		return NoReply(socket);
	}

	static function handleSearch(query:Null<String>, socket:Socket<OptionalAssigns>):HandleEventResult<OptionalAssigns> {
		var summary = query == null ? "all" : query;
		return NoReply(LiveView.assign(socket, "summary", summary));
	}

	static function handleSaveProfile(payload:ProfileForm, socket:Socket<OptionalAssigns>):HandleEventResult<OptionalAssigns> {
		var summary = payload.bio == null ? payload.name : payload.name + ":" + payload.bio;
		return NoReply(LiveView.assign(socket, "summary", summary));
	}
}
