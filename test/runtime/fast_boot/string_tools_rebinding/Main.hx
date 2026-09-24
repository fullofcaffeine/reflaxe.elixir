import elixir.Enum as NativeEnum;
import elixir.types.ReduceWhileResult;

class Main {
	public static function main():Void {
		// A native reducer returns a new value; it must not change the seed binding.
		var seed = 5;
		var total = NativeEnum.reduceWhile([1, 2], seed, function(value:Int, acc:Int) {
			return Cont(acc + value);
		});
		if (total != 8 || seed != 5)
			throw 'Expected total 8 and unchanged seed 5, got $total and $seed';
		NativeEnum.reduceWhile([3], seed, function(value:Int, acc:Int) {
			return Halt(acc + value);
		});
		if (seed != 5)
			throw 'Discarding a native reducer result must not change seed, got $seed';

		var left = StringTools.lpad("x", "0", 3);
		var right = StringTools.rpad("x", "0", 3);

		if (left != "00x")
			throw 'Expected 00x, got $left';
		if (right != "x00")
			throw 'Expected x00, got $right';
	}
}
