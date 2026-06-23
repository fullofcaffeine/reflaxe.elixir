package;

import ecto.Changeset;
import elixir.types.Term;
import phoenix.Component;
import phoenix.ToFormOptions;
import phoenix.LiveSession;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;
import Types.AppAssigns;
import Types.SearchParams;
import Types.User;
import Types.UserParams;

@:liveview
class AppLive {
	public static function mount(_params:Term, session:Term, socket:Socket<AppAssigns>):MountResult<AppAssigns> {
		var user = {id: 1, name: "Ada"};
		var changeset:Changeset<User, UserParams> = Changeset.change(user, {name: user.name});
		socket = socket.assign({
			form: Component.toForm(changeset, ToFormOptions.build("user", "user-form")),
			searchForm: Component.toFormParams({query: ""}, ToFormOptions.build("search")),
			userId: LiveSession.getInt(session, "user_id")
		});
		return Ok(socket);
	}

	public static function handle_event(_event:String, params:SearchParams, socket:Socket<AppAssigns>):HandleEventResult<AppAssigns> {
		return NoReply(socket.assign(_.searchForm, Component.toFormParams(params, ToFormOptions.build("search"))));
	}
}
