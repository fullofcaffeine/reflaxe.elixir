package todo_insights;

import genes.react.Element;
import genes.ts.Imports;
import haxe.DynamicAccess;

/** Haxe-authored React contract smoke, compiled through the same Genes TSX path. */
class TodoInsightsContractTest {
	static function main():Void {
		var renderToStaticMarkup:Element->String = Imports.namedImport("react-dom/server", "renderToStaticMarkup");

		var valid = rawProps();
		var validHtml = renderToStaticMarkup(TodoInsightsIsland.TodoInsightsBoundary(valid));
		assertContains(validHtml, 'data-testid="todo-insights"');
		assertContains(validHtml, 'data-active-filter="active"');
		assertContains(validHtml, ">7<");

		var invalid = rawProps();
		invalid["unexpected"] = true;
		var invalidHtml = renderToStaticMarkup(TodoInsightsIsland.TodoInsightsBoundary(invalid));
		assertContains(invalidHtml, 'data-testid="todo-insights-error"');
		assertContains(invalidHtml, "Unexpected TodoInsights input: unexpected");
	}

	static function rawProps():DynamicAccess<Dynamic> {
		var raw = new DynamicAccess<Dynamic>();
		raw["title"] = "Typed todo insights";
		raw["total"] = 7;
		raw["completed"] = 3;
		raw["pending"] = 4;
		raw["visible"] = 4;
		raw["filter"] = "active";
		raw["pushEvent"] = function(_event:String, _payload:DynamicAccess<Dynamic>):Void {};
		return raw;
	}

	static function assertContains(value:String, expected:String):Void {
		if (value.indexOf(expected) == -1)
			throw new haxe.Exception('expected rendered HTML to contain "$expected": $value');
	}
}
