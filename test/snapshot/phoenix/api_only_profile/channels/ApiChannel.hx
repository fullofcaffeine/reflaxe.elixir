package channels;

import elixir.types.Term;
import phoenix.channels.JoinResult;

@:native("MyAppWeb.ApiChannel")
@:channel
class ApiChannel {
	public static function join(topic:String, payload:Term, socket:Term):JoinResult<Term>
		return Ok(socket);
}
