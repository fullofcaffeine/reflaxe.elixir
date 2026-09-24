enum Payload<T, E> {
	Success(value:T);
	Failure(error:E);
}

/** An erased wrapper must preserve its nested constructor's payload. */
abstract Result<T, E>(Payload<T, E>) from Payload<T, E> to Payload<T, E> {
	public inline function new(result:Payload<T, E>) {
		this = result;
	}

	public static inline function success<T, E>(value:T):Result<T, E> {
		return new Result(Success(value));
	}
}

class Main {
	static function nested():Result<Result<Int, String>, String> {
		return Result.success(Result.success(42));
	}

	static function read(value:Result<Result<Int, String>, String>):Int {
		return switch value {
			case Success(Success(number)): number;
			default: -1;
		};
	}

	public static function main():Void {
		if (read(nested()) != 42)
			throw "Nested inline abstract lost its payload";
		if (read(Result.success(Result.success(-7))) != -7)
			throw "Nested pattern did not bind the actual payload";
		var innerFailure:Result<Int, String> = Failure("inner");
		if (read(Result.success(innerFailure)) != -1)
			throw "Nested pattern accepted the wrong inner constructor";
		var outerFailure:Result<Result<Int, String>, String> = Failure("outer");
		if (read(outerFailure) != -1)
			throw "Nested pattern accepted the wrong outer constructor";
	}
}
