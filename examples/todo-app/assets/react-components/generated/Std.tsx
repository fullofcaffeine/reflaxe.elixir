import {Register} from "./genes/Register.js"

/**
 * The Std class provides standard methods for manipulating basic types.
 */
export class Std {
	static get __name__(): string {
		return "Std"
	}
	get __class__(): Function {
		return Std
	}
}
Register.setHxClass("Std", Std);

;{
	String.__name__ = true;
	Array.__name__ = true;
}

//# sourceMappingURL=Std.tsx.map