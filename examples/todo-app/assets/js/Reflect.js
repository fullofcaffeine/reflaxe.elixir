import {Register} from "./genes/Register.js"

const $global = Register.$global

/**
The Reflect API is a way to manipulate values dynamically through an
abstract interface in an untyped manner. Use with care.

@see https://haxe.org/manual/std-reflection.html
*/
export const Reflect = Register.global("$hxClasses")["Reflect"] = 
class Reflect {
	
	/**
	Returns the value of the field named `field` on object `o`.
	
	If `o` is not an object or has no field named `field`, the result is
	null.
	
	If the field is defined as a property, its accessors are ignored. Refer
	to `Reflect.getProperty` for a function supporting property accessors.
	
	If `field` is null, the result is unspecified.
	*/
	static field(o, field) {
		try {
			return o[field];
		}catch (_g) {
			return null;
		};
	}
	
	/**
	Removes the field named `field` from structure `o`.
	
	This method is only guaranteed to work on anonymous structures.
	
	If `o` or `field` are null, the result is unspecified.
	*/
	static deleteField(o, field) {
		if (!Object.prototype.hasOwnProperty.call(o, field)) {
			return false;
		};
		delete(o[field]);
		return true;
	}
	static get __name__() {
		return "Reflect"
	}
	get __class__() {
		return Reflect
	}
}

