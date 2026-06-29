import elixir.ElixirMap;
import elixir.types.Term;
import phoenix.Params;
import reflaxe.elixir.Pipe;

using reflaxe.elixir.Pipe;

abstract ResourceId(Int) from Int to Int {
	public inline function new(value:Int) {
		this = value;
	}
}

class ResourceIds {
	public static function fromParam(value:Null<String>):Null<ResourceId> {
		if (value == null)
			return null;

		var parsed = Std.parseInt(value);
		return parsed != null && parsed > 0 ? new ResourceId(parsed) : null;
	}

	public static function toDisplay(id:Null<ResourceId>):String {
		return id == null ? "missing" : Std.string((id : Int));
	}
}

class Main {
	public static function fromImperative(params:Term):Null<ResourceId> {
		var raw = ElixirMap.get(params, "resource_id");
		var text = Params.stringFromTerm(raw);
		return ResourceIds.fromParam(text);
	}

	public static function fromNested(params:Term):Null<ResourceId> {
		return ResourceIds.fromParam(Params.stringFromTerm(ElixirMap.get(params, "resource_id")));
	}

	public static function fromExplicitPipe(params:Term):String {
		return (Pipe.of(params) >> (p -> ElixirMap.get(p, "resource_id")) >> Params.stringFromTerm >> ResourceIds.fromParam >> ResourceIds.toDisplay).value();
	}

	public static function fromExtensionPipe(params:Term):Null<ResourceId> {
		return params.pipe() >> (p -> ElixirMap.get(p, "resource_id")) >> Params.stringFromTerm >> ResourceIds.fromParam;
	}

	static function main() {
		var params:Term = untyped __elixir__('%{"resource_id" => "42"}');
		var summary = [
			ResourceIds.toDisplay(fromImperative(params)),
			ResourceIds.toDisplay(fromNested(params)),
			fromExplicitPipe(params),
			ResourceIds.toDisplay(fromExtensionPipe(params))
		];

		untyped __elixir__('IO.inspect({0})', summary);
	}
}
