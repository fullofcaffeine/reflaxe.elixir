import elixir.Tuple;
import elixir.types.Term;

class Main {
	static function main() {
		var okResult:Term = cast Tuple.ok("created");
		var errorResult:Term = cast Tuple.error("invalid");

		if (!Tuple.isOkTuple(okResult)) {
			throw "ok tuple did not match";
		}
		if (!Tuple.isErrorTuple(errorResult)) {
			throw "error tuple did not match";
		}
		if (Tuple.isErrorTuple(okResult)) {
			throw "ok tuple matched error";
		}
		if (Tuple.isOkTuple(errorResult)) {
			throw "error tuple matched ok";
		}

		var okValue:Term = Tuple.getOkValue(okResult);
		var errorReason:Term = Tuple.getErrorReason(errorResult);

		var okValueMatches:Bool = untyped __elixir__('{0} == "created"', okValue);
		var errorReasonMatches:Bool = untyped __elixir__('{0} == "invalid"', errorReason);

		if (!okValueMatches) {
			throw "ok tuple value was not extracted";
		}
		if (!errorReasonMatches) {
			throw "error tuple reason was not extracted";
		}
	}
}
