package phoenix_live_react_tooling;

import elixir.types.Atom;

/** Immutable file snapshot used by the ownership-safe publication protocol. */
typedef PatchFileState = {
	state:Atom,
	?content:String,
	?sha256:String,
	?mode:Int
}

/** One target plus the transaction-owned temporary paths that stage it. */
typedef StagedPatchOperation = {
	operation:PatchOperation,
	newPath:Null<String>,
	?newRelative:Null<String>,
	backupPath:Null<String>,
	?backupRelative:Null<String>
}

/** Complete journal-backed publication state. */
typedef PatchTransaction = {
	root:String,
	directory:String,
	id:String,
	operations:Array<StagedPatchOperation>,
	createdDirs:Array<String>
}
