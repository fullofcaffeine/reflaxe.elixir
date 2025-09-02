import {Exception} from "./Exception.js"
import {Register} from "../genes/Register.js"

/**
An exception containing arbitrary value.

This class is automatically used for throwing values, which don't extend `haxe.Exception`
or native exception type.
For example:
```haxe
throw "Terrible error";
```
will be compiled to
```haxe
throw new ValueException("Terrible error");
```
*/
export const ValueException = Register.global("$hxClasses")["haxe.ValueException"] = 
class ValueException extends Register.inherits(() => Exception, true) {
	[Register.new](value, previous, $native) {
		super[Register.new](String(value), previous, $native);
		this.value = value;
	}
	
	/**
	Extract an originally thrown value.
	
	This method must return the same value on subsequent calls.
	Used internally for catching non-native exceptions.
	Do _not_ override unless you know what you are doing.
	*/
	unwrap() {
		return this.value;
	}
	static get __name__() {
		return "haxe.ValueException"
	}
	static get __super__() {
		return Exception
	}
	get __class__() {
		return ValueException
	}
}
ValueException.prototype.value = null;

