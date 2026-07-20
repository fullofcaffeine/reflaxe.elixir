import elixir.OptionParser;

class Main {
	static function main():Void {
		var parsed = OptionParser.parse([], []);
		parsed.options = [];
	}
}
