package live;

import haxe.test.Assert;
import haxe.test.ExUnit.TestCase;
import haxe.functional.Result;

/**
 * ExUnit tests for SearchDomain.
 */
@:exunit
class SearchDomainTest extends TestCase {
	@:test
	function applyReturnsAllItemsForEmptyQuery() {
		var catalog = ["Phoenix", "Ecto", "LiveView"];
		var result = SearchDomain.apply("", catalog);

		switch (result) {
			case Ok(state):
				Assert.equals(3, state.result_count, "Empty query should keep all entries");
				Assert.equals(catalog, state.visible, "Visible list should match full catalog");
			case Error(message):
				Assert.fail('Unexpected error: ${message}');
		}
	}

	@:test
	function applyFiltersCaseInsensitively() {
		var catalog = ["Phoenix LiveView", "GenServer", "Supervision Trees"];
		var result = SearchDomain.apply("live", catalog);

		switch (result) {
			case Ok(state):
				Assert.equals(1, state.result_count, "Should keep only one match");
				Assert.equals("Phoenix LiveView", state.visible[0], "Should match regardless of case");
			case Error(message):
				Assert.fail('Unexpected error: ${message}');
		}
	}

	@:test
	function applyRejectsNullQuery() {
		var catalog = ["Phoenix", "Ecto"];
		var result = SearchDomain.apply(null, catalog);

		switch (result) {
			case Error(message):
				Assert.equals("query cannot be null", message, "Null query should be rejected explicitly");
			case Ok(_):
				Assert.fail("Expected null query to return Error");
		}
	}
}
