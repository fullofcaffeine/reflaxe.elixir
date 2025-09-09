package;

/**
 * Snapshot: Generic DB types module generation via @:dbTypes
 *
 * WHY
 * - Phoenix/Ecto projects commonly precompile database type encoders/decoders to avoid
 *   runtime races in Postgrex.TypeManager when the Repo pool starts multiple connections.
 * - This test validates a typed, Haxe-owned way to generate that module body deterministically,
 *   keeping the todo-app and other examples as “typed Elixir” (1:1 Phoenix semantics).
 *
 * WHAT
 * - An extern annotated with @:native("MyApp.PostgrexTypes") and @:dbTypes("postgrex", "Jason").
 * - The compiler detects @:dbTypes, captures adapter/json settings, and emits the module body:
 *     defmodule MyApp.PostgrexTypes do
 *       Postgrex.Types.define(__MODULE__, [], json: Jason)
 *     end
 * - See intended/my_app/postgrex_types.ex for the expected output.
 *
 * HOW
 * - Detection: ModuleBuilder sets metadata (isDbTypes=true, dbAdapter="postgrex", jsonModule="Jason").
 * - Transformation: AnnotationTransforms.dbTypesTransformPass emits Types.define(...) at module scope.
 * - This mirrors the idiomatic Elixir approach (MyApp.PostgrexTypes) without hand-writing .ex files.
 *
 * REPO USAGE
 * - Configure the Repo in dev/test/prod configs with:
 *     types: MyApp.PostgrexTypes
 * - This removes the runtime type compilation path and the known TypeManager race.
 *
 * DEFAULT TYPES VS PRECOMPILED
 * - Alternative: `types: Postgrex.DefaultTypes` in Repo config (no generated module, adequate for defaults).
 * - Precompiled module recommended when:
 *   - You want deterministic startup with no on-demand compilation.
 *   - You plan to add custom extensions/domains later.
 *
 * VALIDATION
 * - Snapshot harness compiles this file to Elixir and compares against intended/.
 * - test/validate_elixir.sh also parse-checks the generated .ex using Code.string_to_quoted (no execution).
 */
@:native("MyApp.PostgrexTypes")
@:dbTypes("postgrex", "Jason")
extern class PostgrexTypes {}
