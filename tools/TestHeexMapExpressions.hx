package tools;

#if macro
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.builders.HeexFragmentBuilder;

/** Proves map literals remain structured without classifying unsupported expressions by prefix. */
class TestHeexMapExpressions {
	public static function run():Expr {
		switch (attribute('%{title: "Hello", nested: %{count: 2}, enabled: true}').def) {
			case EMap([
				{key: {def: EAtom(title)}, value: {def: EString("Hello")}},
				{key: {def: EAtom(nested)}, value: {def: EMap([{key: {def: EAtom(count)}, value: {def: EInteger(2)}}])}},
				{key: {def: EAtom(enabled)}, value: {def: EBoolean(true)}}
			]) if ((title : String) == "title"
				&& (nested : String) == "nested" && (count : String) == "count" && (enabled : String) == "enabled"):
			default:
				throw "Expected a structured nested map, including every key and value";
		}
		switch (attribute("%{}").def) {
			case EMap([]):
			default:
				throw "Expected an empty map";
		}
		for (source in [
			"%{title: value()}",
			"%{base | title: 1}",
			"%{title: 1} |> Map.size()",
			"%{title: 1}.title",
			"%{title: 1} + 2"
		]) {
			switch (attribute(source).def) {
				case ERaw(preserved) if (preserved == source):
				default:
					throw 'Unsupported expression must remain intact: $source';
			}
		}
		switch (attribute("%{title: 1} == %{}").def) {
			case EBinary(Equal, {def: EMap(_)}, {def: EMap([])}):
			default:
				throw "A map comparison is a boolean expression, not a map";
		}
		Sys.println("HEEx map expression contract passed");
		return macro null;
	}

	static function attribute(source:String):ElixirAST {
		return switch (HeexFragmentBuilder.build('<.card value={' + source + '} />')) {
			case [{def: EFragment(".card", [{name: "value", value: value}], [])}]: value;
			default: throw 'Expected one component attribute: $source';
		};
	}
}
#end
