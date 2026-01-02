import {Register} from "./genes/Register.js"

const $global = Register.$global

/**
The Std class provides standard methods for manipulating basic types.
*/
export const Std = Register.global("$hxClasses")["Std"] = 
class Std {
	static get __name__() {
		return "Std"
	}
	get __class__() {
		return Std
	}
}


;{
}
