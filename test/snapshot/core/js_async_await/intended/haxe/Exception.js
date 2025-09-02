import {ValueException} from "./ValueException.js"
import {Register} from "../genes/Register.js"

/**
Base class for exceptions.

If this class (or derivatives) is used to catch an exception, then
`haxe.CallStack.exceptionStack()` will not return a stack for the exception
caught. Use `haxe.Exception.stack` property instead:
```haxe
try {
throwSomething();
} catch(e:Exception) {
trace(e.stack);
}
```

Custom exceptions should extend this class:
```haxe
class MyException extends haxe.Exception {}
//...
throw new MyException('terrible exception');
```

`haxe.Exception` is also a wildcard type to catch any exception:
```haxe
try {
throw 'Catch me!';
} catch(e:haxe.Exception) {
trace(e.message); // Output: Catch me!
}
```

To rethrow an exception just throw it again.
Haxe will try to rethrow an original native exception whenever possible.
```haxe
try {
var a:Array<Int> = null;
a.push(1); // generates target-specific null-pointer exception
} catch(e:haxe.Exception) {
throw e; // rethrows native exception instead of haxe.Exception
}
```
*/
export const Exception = Register.global("$hxClasses")["haxe.Exception"] = 
class Exception extends Register.inherits(() => Error, true) {
	[Register.new](message, previous, $native) {
		Error.call(this, message);
		this.message = message;
		this.__previousException = previous;
		this.__nativeException = ($native != null) ? $native : this;
	}
	unwrap() {
		return this.__nativeException;
	}
	static caught(value) {
		if (((value) instanceof Exception)) {
			return value;
		} else if (((value) instanceof Error)) {
			return new Exception(value.message, null, value);
		} else {
			return new ValueException(value, null, value);
		};
	}
	static get __name__() {
		return "haxe.Exception"
	}
	static get __super__() {
		return Error
	}
	get __class__() {
		return Exception
	}
}
Exception.prototype.__skipStack = null;
Exception.prototype.__nativeException = null;
Exception.prototype.__previousException = null;

