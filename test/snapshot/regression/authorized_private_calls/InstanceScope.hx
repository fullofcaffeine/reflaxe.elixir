@:allow(Reader)
class InstanceScope {
	final amount:Int;

	private function new(amount:Int)
		this.amount = amount;

	private function value():Int
		return localValue();

	private function localValue():Int
		return amount;
}
