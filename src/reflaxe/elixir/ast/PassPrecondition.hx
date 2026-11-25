package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
/**
 * A cheap fact that must be present in a module before a pass can change it.
 *
 * WHAT
 * - Each value names one structural fact of the current module tree, such as
 *   "the module contains a `Phoenix.Controller.json` call" or "the module
 *   contains an `EStructUpdate` node".
 * - `PassFeatureScan` reads these facts from the tree in one walk.
 *
 * WHY
 * - Most transform passes find nothing to do in most modules. On a warm todo-app
 *   edit, 515 of the 555 passes that run on `TodoAppWeb.TodoLive` leave it
 *   unchanged, but each one still walks the whole tree. A pass whose required fact
 *   is absent cannot change the tree, so the runner skips it without a walk.
 *
 * HOW
 * - A precondition is a NECESSARY condition: "if the pass can change this tree,
 *   the fact is present". It never has to be sufficient. When the fact is present
 *   the pass runs normally and may still decide to do nothing.
 * - A pass without a precondition always runs. A precondition can only remove a
 *   run, so a missing declaration is always safe.
 * - Declarations live in `PassPreconditionManifest`, next to the pass scopes.
 *   `-D reflaxe_elixir_verify_pass_preconditions` runs every skipped pass anyway
 *   and fails the build if the skipped pass would have changed the tree.
 *
 * EXAMPLE
 * - `WebJsonSecondArgRewrite_Ultimate` only rewrites
 *   `Phoenix.Controller.json(conn, data)`. Its precondition is
 *   `CallTo("Phoenix.Controller", "json")`. A LiveView module without that call
 *   skips the pass.
 *
 * COMMON MISTAKE
 * - Declaring a fact that is only typical for the pass, not required. If the pass
 *   can also change a tree without the fact, the skip changes generated code. The
 *   verification mode and the snapshot suite catch this; read every match arm of
 *   the pass before declaring a precondition.
 */
enum PassPrecondition {
	/**
	 * The tree contains a node built with this `ElixirASTDef` constructor, for
	 * example `"EStructUpdate"`. The name is checked against the enum when the
	 * manifest is built, so a misspelled name fails the build.
	 */
	HasNode(constructorName:String);

	/**
	 * The tree contains `module.fn(...)`: `ERemoteCall(EVar(module) | EAlias(module), fn, _)`
	 * or `ECall(EVar(module), fn, _)`.
	 */
	CallTo(module:String, fn:String);

	/** The tree contains a local or remote call (`ECall` or `ERemoteCall`) named `fn`. */
	CallNamed(fn:String);

	/**
	 * The tree contains a variable or binder name with this property. Names come from
	 * `EVar`, from every `PVar` and `PAlias` in every pattern position (function and
	 * fn arguments, matches, case, receive, with, for, rescue, and catch clauses), and
	 * from rescue clause variables. Names inside `ERaw` text are not seen.
	 */
	HasName(feature:PassNameFeature);

	/** At least one of the conditions holds. */
	AnyOf(conditions:Array<PassPrecondition>);

	/** Every one of the conditions holds. */
	AllOf(conditions:Array<PassPrecondition>);
}

/** A property of one variable or binder name, used by `HasName`. */
enum PassNameFeature {
	/** The name is exactly this text, for example `"socket"`. */
	Exactly(name:String);

	/** The name starts with this text, for example `"this"`. */
	StartsWith(prefix:String);

	/** The name starts with `_` and has more than one character, for example `_value`. */
	UnderscoredBinder;

	/**
	 * The name contains an upper-case letter: a character that `toLowerCase` changes,
	 * for example `userId`. This covers ASCII `A` to `Z` and other cased letters.
	 */
	HasUppercase;

	/** The name ends with an ASCII digit, for example `value2`. */
	EndsWithDigit;
}
#end
