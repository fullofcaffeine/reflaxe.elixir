import {Exception} from "./haxe/Exception.js"
import {Register} from "./genes/Register.js"
import {Std} from "./Std.js"

/**
* Simple test to verify async/await type safety
*/
export const TestAsyncSimple = Register.global("$hxClasses")["TestAsyncSimple"] = 
class TestAsyncSimple {
	static async test1() {
		let num = await Promise.resolve(42);
		return Promise.resolve(num + 1);
	}
	static async test2() {
		let str = await Promise.resolve("hello");
		return Promise.resolve(str.toUpperCase());
	}
	static async testError() {
		try {
			await Promise.reject("error");
			return Promise.resolve("not reached");
		}catch (_g) {
			let e = Exception.caught(_g).unwrap();
			return Promise.resolve("Caught: " + Std.string(e));
		};
	}
	static main() {
		console.log("TestAsyncSimple.hx:34:","Tests compiled successfully");
	}
	static get __name__() {
		return "TestAsyncSimple"
	}
	get __class__() {
		return TestAsyncSimple
	}
}

