/** Immutable fields must survive a null guard and whole-record use. */
typedef Payload = {final identity:String; final sequence:Int;}

/** Native callers supply both present and absent records. */
typedef Envelope = {final pending:Null<Payload>;}

/** Regression for haxe.elixir.codex-tg3; runtime.exs observes values independently. */
@:keep
class Main {
	static function main():Void {}

	public static function copy(envelope:Envelope, observe:Payload->Void):Payload {
		final pending = envelope.pending;
		if (pending == null)
			throw "missing";
		observe(pending);
		return {identity: pending.identity, sequence: pending.sequence};
	}
}
