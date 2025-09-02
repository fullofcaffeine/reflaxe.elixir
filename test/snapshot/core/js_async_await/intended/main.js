import {Exception} from "./haxe/Exception.js"
import {Register} from "./genes/Register.js"
import {Std} from "./Std.js"

/**
* Comprehensive async/await test suite for Haxe→JavaScript compilation.
*
* This test validates full 1:1 parity with JavaScript/TypeScript async/await:
*
* WHAT THIS TESTS:
* ================
* 1. Clean ES6 async/await generation without wrappers
* 2. Automatic Promise wrapping (return 42 → Promise.resolve(42))
* 3. Type unwrapping (@:await Promise<T> → T)
* 4. Exception handling with try/catch
* 5. Error propagation through async chains
* 6. Promise.all and Promise.race integration
* 7. Type safety and compile-time checking
* 8. Inline async functions
* 9. Nested try/catch with re-throwing
*
* IMPLEMENTATION DETAILS:
* =======================
* - Uses @:async/@:await metadata (Haxe doesn't have native keywords)
* - Requires @:build(genes.AsyncMacro.build()) for transformation
* - Generates clean ES6 without __async_marker__ in output
* - Full Promise<T> type parameterization preserved
*
* JAVASCRIPT EQUIVALENCE:
* =======================
* Haxe:       @:async function foo(): Promise<String>
* JavaScript: async function foo(): Promise<string>
*
* Haxe:       var x = @:await somePromise;
* JavaScript: let x = await somePromise;
*
* @see docs/04-api-reference/async-await-specification.md
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
	* Test automatic Promise wrapping (1:1 with JavaScript).
	*/
	static async automaticWrappingTest() {
		return Promise.resolve("automatically wrapped");
	}
	
	/**
	* Test error propagation through async chain.
	*/
	static async errorPropagationTest() {
		try {
			let result = await Main.throwingAsyncFunction();
			return Promise.resolve("Should not reach");
		}catch (_g) {
			let e = Exception.caught(_g).unwrap();
			return Promise.resolve("Propagated: " + Std.string(e));
		};
	}
	static async throwingAsyncFunction() {
		throw Exception.thrown("Async error");
	}
	
	/**
	* Test Promise.all with async/await.
	*/
	static async promiseAllTest() {
		let promises = [Promise.resolve("A"), Promise.resolve("B"), Promise.resolve("C")];
		let results = await Promise.all(promises);
		return Promise.resolve(results.join("-"));
	}
	
	/**
	* Test Promise.race with async/await.
	* Note: In Node.js environment, we use immediate resolution instead of setTimeout.
	*/
	static async promiseRaceTest() {
		let fast = Promise.resolve("fast");
		let slow = Promise.resolve("slow");
		return Promise.resolve(await Promise.race([slow,fast]));
	}
	
	/**
	* Test chained async operations.
	*/
	static async chainedAsyncTest() {
		let a = await Promise.resolve(10);
		let b = await Main.addAsync(a,5);
		let c = await Main.multiplyAsync(b,2);
		return Promise.resolve(c);
	}
	static async addAsync(x, y) {
		return Promise.resolve(x + y);
	}
	static async multiplyAsync(x, y) {
		return Promise.resolve(x * y);
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
		console.log("Main.hx:269:","✓ " + message);
	}
	
	/**
	* Async assertion helper with comprehensive testing.
	*/
	static async runTests() {
		console.log("Main.hx:277:","Running comprehensive async/await tests...");
		console.log("Main.hx:278:","=======================================");
		console.log("Main.hx:281:","\n[TEST 1] Basic async/await:");
		let result1 = await Main.simpleAsync();
		Main.assert(result1 == "Hello World", "Basic async function returns correct value");
		Main.assert(typeof(result1) == "string", "Return type is String as expected");
		console.log("Main.hx:287:","\n[TEST 2] Multiple awaits:");
		let result2 = await Main.multipleAwaits();
		Main.assert(result2 == "First-Second-Third", "Multiple awaits work correctly");
		console.log("Main.hx:292:","\n[TEST 3] Error handling:");
		let result3 = await Main.errorHandling();
		Main.assert(result3 == "Caught: Test Error", "Try/catch catches Promise rejections");
		console.log("Main.hx:297:","\n[TEST 4] Conditional async:");
		let result4a = await Main.conditionalAsync(true);
		Main.assert(result4a == "Async path", "Conditional async with true");
		let result4b = await Main.conditionalAsync(false);
		Main.assert(result4b == "Sync path", "Conditional async with false");
		console.log("Main.hx:304:","\n[TEST 5] Nested try/catch:");
		let result5 = await Main.nestedErrorHandling();
		Main.assert(result5.indexOf("Wrapped:") >= 0, "Nested error handling with re-throw works");
		console.log("Main.hx:309:","\n[TEST 6] Type enforcement:");
		let result6 = await Main.typeEnforcementTest();
		Main.assert(result6 == 84, "Promise<Int> type enforced correctly");
		Main.assert(typeof(result6) == "number" && ((result6 | 0) === (result6)), "Result is Int type");
		console.log("Main.hx:315:","\n[TEST 7] Automatic Promise wrapping:");
		let result7 = await Main.automaticWrappingTest();
		Main.assert(result7 == "automatically wrapped", "Non-Promise returns are auto-wrapped");
		console.log("Main.hx:320:","\n[TEST 8] Error propagation:");
		let result8 = await Main.errorPropagationTest();
		Main.assert(result8 == "Propagated: Async error", "Errors propagate through async chain");
		console.log("Main.hx:325:","\n[TEST 9] Promise.all:");
		let result9 = await Main.promiseAllTest();
		Main.assert(result9 == "A-B-C", "Promise.all works with await");
		console.log("Main.hx:330:","\n[TEST 10] Promise.race:");
		let result10 = await Main.promiseRaceTest();
		Main.assert(result10 == "fast" || result10 == "slow", "Promise.race returns one of the results");
		console.log("Main.hx:335:","\n[TEST 11] Chained async:");
		let result11 = await Main.chainedAsyncTest();
		Main.assert(result11 == 30, "Chained async operations maintain correct values");
		console.log("Main.hx:340:","\n[TEST 12] Type unwrapping:");
		let result12 = await Main.typeUnwrappingTest();
		Main.assert(result12 == true, "Promise<T> unwraps to T correctly");
		console.log("Main.hx:345:","\n[TEST 13] Finally simulation:");
		let result13 = await Main.finallySimulation();
		Main.assert(result13 == "Success", "Finally simulation works");
		console.log("Main.hx:350:","\n[TEST 14] Non-async functions:");
		let regular = Main.regularFunction();
		Main.assert(regular == "Not async", "Regular functions remain synchronous");
		console.log("Main.hx:354:","\n=======================================");
		console.log("Main.hx:355:","✅ All async/await tests passed!");
		console.log("Main.hx:356:","Total tests: 14");
		console.log("Main.hx:357:","=======================================");
		return Promise.resolve();
	}
	
	/**
	* Static entry point (non-async).
	*/
	static main() {
		Main.inlineAsyncTest();
		Main.runTests().then(function (_) {
			console.log("Main.hx:371:","Test suite completed successfully");
		}, function (error) {
			console.log("Main.hx:372:","Test suite failed: " + error);
		});
	}
	static get __name__() {
		return "Main"
	}
	get __class__() {
		return Main
	}
}

