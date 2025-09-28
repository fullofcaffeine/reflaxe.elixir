class Main {
	static function main() {
		// This pattern should trigger infrastructure variable generation
		for (i in 0...3) {
			switch (compute(i)) {
				case Ok(value): trace("Got: " + value);
				case Error(msg): trace("Error: " + msg);
			}
		}
	}
	
	static function compute(n: Int): Result<String, String> {
		return if (n > 0) Ok("Value " + n) else Error("Invalid");
	}
}

enum Result<T, E> {
	Ok(value: T);
	Error(error: E);
}