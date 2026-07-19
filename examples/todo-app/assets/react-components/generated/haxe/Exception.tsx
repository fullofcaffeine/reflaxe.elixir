import {ValueException} from "./ValueException.js"
import {Register} from "../genes/Register.js"

/**
 * Base class for exceptions.
 *
 * If this class (or derivatives) is used to catch an exception, then
 * `haxe.CallStack.exceptionStack()` will not return a stack for the exception
 * caught. Use `haxe.Exception.stack` property instead:
 * ```haxe
 * try {
 * throwSomething();
 * } catch(e:Exception) {
 * trace(e.stack);
 * }
 * ```
 *
 * Custom exceptions should extend this class:
 * ```haxe
 * class MyException extends haxe.Exception {}
 * //...
 * throw new MyException('terrible exception');
 * ```
 *
 * `haxe.Exception` is also a wildcard type to catch any exception:
 * ```haxe
 * try {
 * throw 'Catch me!';
 * } catch(e:haxe.Exception) {
 * trace(e.message); // Output: Catch me!
 * }
 * ```
 *
 * To rethrow an exception just throw it again.
 * Haxe will try to rethrow an original native exception whenever possible.
 * ```haxe
 * try {
 * var a:Array<Int> = null;
 * a.push(1); // generates target-specific null-pointer exception
 * } catch(e:haxe.Exception) {
 * throw e; // rethrows native exception instead of haxe.Exception
 * }
 * ```
 */
export class Exception extends (Register.inherits(() => Error, true) as typeof Error) {
	constructor(message: string, previous: Exception | null = null, $native: unknown | null = null) {
		// @ts-ignore
		super(message, previous, $native);
	}
	declare message: string;
	declare __skipStack: number;
	declare __nativeException: unknown;
	declare __previousException: Exception | null;
	[Register.new](...args: never[]): void;
	[Register.new](message: string, previous: Exception | null = null, $native: unknown | null = null): void {
		Error.call(this, message);
		this.message = message;
		this.__previousException = previous;
		this.__nativeException = ($native != null) ? $native : this;
	}

	/**
	 * Returns exception message.
	 */
	toString(): string {
		return this.get_message();
	}
	get_message(): string {
		return this.message;
	}
	static caught(value: unknown): Exception {
		if (((value) instanceof Exception)) {
			return value;
		} else if (((value) instanceof Error)) {
			return new Exception(value.message, null, value);
		} else {
			return new ValueException(value, null, value);
		};
	}
	static get __name__(): string {
		return "haxe.Exception"
	}
	static get __super__(): Function {
		return Error
	}
	get __class__(): Function {
		return Exception
	}
}
Register.setHxClass("haxe.Exception", Exception);

Register.seedProtoField(Exception, "message");

Register.seedProtoField(Exception, "__skipStack");

Register.seedProtoField(Exception, "__nativeException");

Register.seedProtoField(Exception, "__previousException");

//# sourceMappingURL=Exception.tsx.map