/**
 * Test that pattern-bound variables are used directly without nil assignments
 *
 * This validates the architectural fix where SwitchBuilder and BlockBuilder
 * call ElixirASTBuilder.buildFromTypedExpr directly instead of
 * compiler.compileExpressionImpl, preserving ClauseContext registrations.
 */

enum Result<T, E> {
	Ok(value: T);
	Error(error: E);
}

class Main {
	public static function main() {
		var result = Ok("success");

		// Pattern variables should be used directly from the pattern
		// WITHOUT generating "value = nil" or "error = nil" assignments
		var message = switch(result) {
			case Ok(value):
				"Success: " + value;  // 'value' from pattern should be used directly
			case Error(error):
				"Error: " + error;     // 'error' from pattern should be used directly
		}

		trace(message);
	}
}
