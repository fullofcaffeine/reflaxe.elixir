import {Exception} from "./haxe/Exception.js"
import {Register} from "./genes/Register.js"
import {Std} from "./Std.js"

/**
* Test async/await JavaScript generation with genes.
*
* This test validates that @:async functions generate proper
* JavaScript async function declarations and @:await expressions
* work correctly with the genes ES6 generator.
*/
export const Main = Register.global("$hxClasses")["Main"] = 
class Main {
	
	/**
	* Basic async function test.
	*/
	static async simpleAsync() {
		let greeting = await Promise.resolve("Hello");
		return Promise.resolve(greeting + " World");
	}
	
	/**
	* Multiple await expressions test.
	*/
	static async multipleAwaits() {
		let first = await Promise.resolve("First");
		let second = await Promise.resolve("Second");
		let third = await Promise.resolve("Third");
		return Promise.resolve(first + "-" + second + "-" + third);
	}
	
	/**
	* Error handling with try/catch test.
	*/
	static async errorHandling() {
		try {
			let result = await Promise.reject("Test Error");
			return Promise.resolve("Should not reach here");
		}catch (_g) {
			let error = Exception.caught(_g).unwrap();
			return Promise.resolve("Caught: " + Std.string(error));
		};
	}
	
	/**
	* Conditional async operations test.
	*/
	static async conditionalAsync(useAsync) {
		if (useAsync) {
			let result = await Promise.resolve("Async path");
			return Promise.resolve(result);
		} else {
			return Promise.resolve("Sync path");
		};
	}
	
	/**
	* Test nested try/catch with different error types.
	*/
	static async nestedErrorHandling() {
		try {
			try {
				await Promise.reject({"code": 404, "message": "Not found"});
				return Promise.resolve("Should not reach");
			}catch (_g) {
				let e = Exception.caught(_g).unwrap();
				throw Exception.thrown("Wrapped: " + Std.string(e.message));
			};
		}catch (_g) {
			let _g1 = Exception.caught(_g).unwrap();
			if (typeof(_g1) == "string") {
				let e = _g1;
				return Promise.resolve("Caught string: " + e);
			} else {
				throw _g;
			};
		};
	}
	
	/**
	* Test that async functions enforce Promise<T> return type.
	*/
	static async typeEnforcementTest() {
		let value = await Promise.resolve(42);
		return Promise.resolve(value * 2);
	}
	
	/**
	* Test Promise<T> type unwrapping with await.
	*/
	static async typeUnwrappingTest() {
		let str = await Promise.resolve("test");
		let num = await Promise.resolve(42);
		let result = str.length == 4 && num == 42;
		return Promise.resolve(result);
	}
	
	/**
	* Test try/catch with finally simulation (Haxe doesn't have finally).
	*/
	static async finallySimulation() {
		let cleanup = false;
		try {
			await Promise.resolve("success");
			cleanup = true;
			return Promise.resolve("Success");
		}catch (_g) {
			let e = Exception.caught(_g).unwrap();
			cleanup = true;
			return Promise.resolve("Error: " + Std.string(e));
		};
	}
	
	/**
	* Inline async function test with @:async metadata.
	*/
	static inlineAsyncTest() {
		let fetchData = async function () {
			let data = await Promise.resolve("Inline async data");
			return Promise.resolve("Fetched: " + data);
		};
		let processData = async function (input) {
			try {
				if (input == "error") {
					await Promise.reject("Invalid input");
				};
				let processed = await Promise.resolve(input.toUpperCase());
				return Promise.resolve("Processed: " + processed);
			}catch (_g) {
				let e = Exception.caught(_g).unwrap();
				return Promise.resolve("Error processing: " + Std.string(e));
			};
		};
		let computeValue = async function (x, y) {
			let sum = await Promise.resolve(x + y);
			return Promise.resolve(sum * 2);
		};
	}
	
	/**
	* Regular function (should not have async keyword).
	*/
	static regularFunction() {
		return "Not async";
	}
	
	/**
	* Simple assertion helper.
	*/
	static assert(condition, message) {
		if (!condition) {
			throw Exception.thrown("Assertion failed: " + message);
		};
		console.log("Main.hx:165:","✓ " + message);
	}
	
	/**
	* Async assertion helper.
	*/
	static async runTests() {
		console.log("Main.hx:173:","Running async/await tests...");
		let result1 = await Main.simpleAsync();
		Main.assert(result1 == "Hello World", "Basic async function returns correct value");
		let result2 = await Main.multipleAwaits();
		Main.assert(result2 == "First-Second-Third", "Multiple awaits work correctly");
		let result3 = await Main.errorHandling();
		Main.assert(result3 == "Caught: Test Error", "Error handling catches rejections");
		let result4a = await Main.conditionalAsync(true);
		Main.assert(result4a == "Async path", "Conditional async with true");
		let result4b = await Main.conditionalAsync(false);
		Main.assert(result4b == "Sync path", "Conditional async with false");
		let result5 = await Main.nestedErrorHandling();
		Main.assert(result5.indexOf("Wrapped:") >= 0, "Nested error handling works");
		let result6 = await Main.typeEnforcementTest();
		Main.assert(result6 == 84, "Type enforcement returns correct Int");
		let result7 = await Main.typeUnwrappingTest();
		Main.assert(result7 == true, "Type unwrapping preserves types correctly");
		let result8 = await Main.finallySimulation();
		Main.assert(result8 == "Success", "Finally simulation completes successfully");
		console.log("Main.hx:209:","All tests passed!");
		return Promise.resolve();
	}
	
	/**
	* Static entry point (non-async).
	*/
	static main() {
		Main.inlineAsyncTest();
		Main.runTests().then(function (_) {
			console.log("Main.hx:222:","Test suite completed successfully");
		}, function (error) {
			console.log("Main.hx:223:","Test suite failed: " + error);
		});
	}
	static get __name__() {
		return "Main"
	}
	get __class__() {
		return Main
	}
}

