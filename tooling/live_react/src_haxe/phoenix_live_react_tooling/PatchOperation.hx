package phoenix_live_react_tooling;

import elixir.types.Atom;
import phoenix_live_react_tooling.PatchTypes.PatchFileState;

/** Explicit native-value ABI for `%HaxeProjectPatch.Operation{}`. */
@:keep
@:elixirStruct
@:native("HaxeProjectPatch.Operation")
class PatchOperation {
	public var kind:Atom;
	public var path:String;
	public var relative:String;
	public var before:PatchFileState;
	public var after:PatchFileState;
	public var action:Atom;
	@:native("manifest?") public var manifest:Bool;

	public function new(kind:Atom, path:String, relative:String, before:PatchFileState, after:PatchFileState, action:Atom, manifest:Bool = false) {
		this.kind = kind;
		this.path = path;
		this.relative = relative;
		this.before = before;
		this.after = after;
		this.action = action;
		this.manifest = manifest;
	}
}
