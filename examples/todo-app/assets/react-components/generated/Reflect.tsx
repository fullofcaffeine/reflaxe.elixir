import {Register} from "./genes/Register.js"

/**
 * The Reflect API is a way to manipulate values dynamically through an
 * abstract interface in an untyped manner. Use with care.
 *
 * @see https://haxe.org/manual/std-reflection.html
 */
export class Reflect {

	/**
	 * Returns the fields of structure `o`.
	 *
	 * This method is only guaranteed to work on anonymous structures. Refer to
	 * `Type.getInstanceFields` for a function supporting class instances.
	 *
	 * If `o` is null, the result is unspecified.
	 */
	static fields(o: any): string[] {
		let a: string[] = [];
		if (o != null) {
			let hasOwnProperty: Function = Object.prototype.hasOwnProperty;
			for( var f in o ) {;
			if (f != "__id__" && f != "hx__closures__" && hasOwnProperty.call(o, Register.unsafeCast<any[]>(f))) {
				a.push(f);
			};
			};
		};
		return a;
	}

	/**
	 * Returns true if `f` is a function, false otherwise.
	 *
	 * If `f` is null, the result is false.
	 */
	static isFunction(f: any): boolean {
		if (typeof(f) == "function") {
			return !((f!).__name__ || (f!).__ename__);
		} else {
			return false;
		};
	}
	static get __name__(): string {
		return "Reflect"
	}
	get __class__(): Function {
		return Reflect
	}
}
Register.setHxClass("Reflect", Reflect);

//# sourceMappingURL=Reflect.tsx.map