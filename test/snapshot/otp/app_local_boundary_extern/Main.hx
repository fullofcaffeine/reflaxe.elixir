package;

import elixir.otp.Supervisor.ChildSpecFormat;
import elixir.otp.TypeSafeChildSpec;
import infrastructure.PubSub;

class Main {
	static function main() {
		var children:Array<ChildSpecFormat> = [TypeSafeChildSpec.pubSub(PubSub)];
		trace(children);
	}
}
