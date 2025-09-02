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
	* Inline async function test with @:async metadata.
	*/
	static inlineAsyncTest() {
		let fetchData = async function () {
			let data = await Promise.resolve("Inline async data");
			return Promise.resolve("Fetched: " + data);
		};
		let processData = async function (input) {
			let processed = await Promise.resolve(input.toUpperCase());
			return Promise.resolve("Processed: " + processed);
		};
	}
	
	/**
	* Regular function (should not have async keyword).
	*/
	static regularFunction() {
		return "Not async";
	}
	
	/**
	* Static entry point (non-async).
	*/
	static main() {
		Main.inlineAsyncTest();
	}
	static get __name__() {
		return "Main"
	}
	get __class__() {
		return Main
	}
}

