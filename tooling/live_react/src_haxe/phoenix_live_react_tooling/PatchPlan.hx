package phoenix_live_react_tooling;

import elixir.MapSet;
import elixir.types.Term;

/**
 * Explicit native-value ABI for `%HaxeProjectPatch.Plan{}`.
 *
 * The plan is passed through ordinary Phoenix/Mix code and is intentionally a
 * transparent Elixir struct. Every Haxe update returns/rebinds the new value;
 * this is not an ordinary alias-mutable Haxe object.
 */
@:keep
@:elixirStruct
@:native("HaxeProjectPatch.Plan")
class PatchPlan {
	public var root:String;
	public var operations:Array<PatchOperation>;
	public var seenPaths:Term;

	public function new(root:String) {
		this.root = root;
		this.operations = [];
		this.seenPaths = MapSet.new_();
	}
}
