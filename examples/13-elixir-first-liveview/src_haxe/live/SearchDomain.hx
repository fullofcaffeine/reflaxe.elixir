package live;

import elixir.ElixirString;
import elixir.Enum;
import haxe.functional.Result;

typedef SearchState = {
	query:String,
	visible:Array<String>,
	result_count:Int
}

/**
 * Pure search domain logic with explicit Result-based flow.
 */
class SearchDomain {
	public static function apply(query:String, catalog:Array<String>):Result<SearchState, String> {
		if (query == null) {
			return Error("query cannot be null");
		}
		if (catalog == null) {
			return Error("catalog cannot be null");
		}

		var normalized = ElixirString.trim(query);
		if (normalized == "") {
			return Ok({
				query: "",
				visible: catalog,
				result_count: catalog.length
			});
		}

		var needle = ElixirString.downcase(normalized);
		var visible = Enum.filter(catalog, item -> item != null && ElixirString.contains(ElixirString.downcase(item), needle));

		return Ok({
			query: normalized,
			visible: visible,
			result_count: visible.length
		});
	}
}
