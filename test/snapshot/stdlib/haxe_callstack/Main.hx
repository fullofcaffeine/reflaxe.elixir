import haxe.CallStack;

class Main {
	static function main():Void {
		var current:CallStack = CallStack.callStack();
		var copied:CallStack = current.copy();
		var exception = CallStack.exceptionStack(true);
		var shortened = current.subtract(copied);
		var printable = CallStack.toString(current);

		trace(current.length);
		trace(exception.length);
		trace(shortened.length);
		trace(printable);
	}
}
