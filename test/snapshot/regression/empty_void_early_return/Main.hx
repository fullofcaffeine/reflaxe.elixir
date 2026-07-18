package;

import elixir.IO;

class Main {
	static function report(cancelled:Bool):Void {
		if (cancelled) {
			IO.puts("cancelled");
			return;
		}

		IO.puts("continued");
	}

	static function main():Void {
		report(true);
		report(false);
	}
}
