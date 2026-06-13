import elixir.Atom;
import elixir.Kernel;
import elixir.types.Term;
import phoenix.PubSub;

class Main {
	static function main() {}

	public static function subscribeToPresence():Term {
		return PubSub.subscribe(pubsubModule(), "presence:lobby");
	}

	public static function subscribeWithOptions(options:Term):Term {
		return PubSub.subscribeWithOptions(pubsubModule(), "presence:lobby", options);
	}

	public static function broadcastMessage(payload:Term):Term {
		return PubSub.broadcast(pubsubModule(), "chat:lobby", payload);
	}

	public static function broadcastMessageFromSelf(payload:Term):Term {
		return PubSub.broadcastFrom(pubsubModule(), Kernel.self(), "chat:lobby", payload);
	}

	public static function unsubscribeFromPresence():Term {
		return PubSub.unsubscribe(pubsubModule(), "presence:lobby");
	}

	static function pubsubModule():Term {
		return Atom.fromString("Elixir.PhoenixChat.PubSub");
	}
}
