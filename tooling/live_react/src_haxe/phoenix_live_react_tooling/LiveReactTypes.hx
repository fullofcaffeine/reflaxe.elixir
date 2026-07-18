package phoenix_live_react_tooling;

import elixir.types.Atom;
import elixir.types.Term;

/** One closed, statically imported React component registry entry. */
typedef LiveReactComponent = {
	final name:String;
	final modulePath:String;
	final exportName:String;
}

/** Canonical npm and Phoenix source locations discovered before mutation. */
typedef LiveReactTopology = {
	root:String,
	packageRoot:String,
	packageRootRelative:String,
	packageJson:String,
	viteConfig:String,
	hooksFile:String,
	registryFile:String,
	rootLayout:String,
	clientMode:Atom
}

/** One supported package root after physical-path validation. */
typedef LiveReactPackageRoot = {
	relative:String,
	absolute:String
}

/** Hand-owned source files that the lifecycle patches transactionally. */
typedef LiveReactSources = {
	mixExs:String,
	configExs:String,
	devExs:String,
	appJs:String,
	rootLayout:String
}

/** Normalized Mix declaration independent of its tuple spelling. */
typedef LiveReactDependencySource = {
	kind:Atom,
	?repository:String,
	?ref:Null<String>,
	?packageName:String,
	?requirement:String,
	?path:String
}

/** Validated stock LiveReact identity plus ownership/lock publication state. */
typedef LiveReactDependency = {
	identity:Term,
	npmReference:String,
	checkout:String,
	source:LiveReactDependencySource,
	owned:Bool,
	lockOwned:Bool,
	lockContent:String,
	lockChanged:Bool,
	originalLockState:Term
}

/** Identity validation result before ownership data is attached. */
typedef LiveReactResolvedDependency = {
	identity:Term,
	npmReference:String,
	checkout:String,
	source:LiveReactDependencySource
}

/** Input supplied to an injectable or real Mix dependency resolver. */
typedef LiveReactResolverContext = {
	root:String,
	currentLockContent:String,
	dependencies:Array<Term>,
	dependency:Term,
	dependencyOwned:Bool,
	dependencyPath:String
}

/** Resolver output. The dependency path defaults to the requested checkout. */
typedef LiveReactResolverResult = {
	lockContent:String,
	?dependencyPath:String
}

/** Deterministic package.json publication or removal result. */
typedef LiveReactPackagePlan = {
	content:String,
	?ownedKeys:Array<String>,
	?retainedKeys:Array<String>
}

/** Data required to render the versioned integration manifest. */
typedef LiveReactManifestData = {
	topology:LiveReactTopology,
	dependency:LiveReactDependency,
	components:Array<LiveReactComponent>,
	managedFiles:Array<String>,
	packageKeys:Array<String>,
	restores:Term,
	dependencyOwned:Bool,
	lockOwned:Bool
}

/** Result returned from planning before publication or drift validation. */
typedef LiveReactLifecyclePlan = {
	plan:PatchPlan,
	mode:Atom,
	packageRoot:String,
	clientMode:Atom,
	?dependency:Term,
	?npmReference:String,
	?retainedPackageKeys:Array<String>,
	?retainedLiveReactDependency:Bool,
	changes:Array<Term>
}

/** Result returned by component registration/removal planning. */
typedef LiveReactComponentPlan = {
	plan:PatchPlan,
	mode:Atom,
	name:String,
	components:Array<LiveReactComponent>,
	createdFiles:Array<String>,
	retainedFiles:Array<String>,
	changes:Array<Term>
}
