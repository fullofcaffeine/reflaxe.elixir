package unit;

interface IMyParent {}
interface IMyChild extends IMyParent {}
class MyClass {}

class MyParent {
	public function new() {}
}

class MyChild1 extends MyParent implements IMyChild {
	public function new() {
		super();
	}
}
