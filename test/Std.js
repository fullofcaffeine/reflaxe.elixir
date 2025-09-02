import {Boot} from "./js/Boot.js"
import {Register} from "./genes/Register.js"

/**
The Std class provides standard methods for manipulating basic types.
*/
export const Std = Register.global("$hxClasses")["Std"] = 
class Std {
	
	/**
	Converts any value to a String.
	
	If `s` is of `String`, `Int`, `Float` or `Bool`, its value is returned.
	
	If `s` is an instance of a class and that class or one of its parent classes has
	a `toString` method, that method is called. If no such method is present, the result
	is unspecified.
	
	If `s` is an enum constructor without argument, the constructor's name is returned. If
	arguments exists, the constructor's name followed by the String representations of
	the arguments is returned.
	
	If `s` is a structure, the field names along with their values are returned. The field order
	and the operator separating field names and values are unspecified.
	
	If s is null, "null" is returned.
	*/
	static string(s) {
		return Boot.__string_rec(s, "");
	}
	static get __name__() {
		return "Std"
	}
	get __class__() {
		return Std
	}
}


;{
	String.__name__ = true;
	Array.__name__ = true;
}
