using reflaxe.elixir.Pipe;

class Main {
	static function add(left:Int, right:Int):Int {
		return left + right;
	}

	static function main() {
		var value = 1.pipe() >> add;
		trace(value);
	}
}
