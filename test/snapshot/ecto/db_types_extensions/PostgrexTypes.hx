package;

/**
 * Snapshot: Generic @:dbTypes with extensions list
 *
 * WHY
 * - In real apps you may register custom Postgrex extensions/domains (e.g., for custom types).
 *   This snapshot verifies our DSL can pass an extension list through to Types.define/3.
 *
 * WHAT
 * - @:dbTypes("postgrex", "Jason", ["MyExt.One", "MyExt.Two"]) generates:
 *     defmodule MyApp.PostgrexTypes do
 *       Postgrex.Types.define(__MODULE__, [], json: Jason, extensions: [MyExt.One, MyExt.Two])
 *     end
 * - See intended/my_app/postgrex_types.ex for the expected output.
 *
 * HOW
 * - ModuleBuilder parses the third param as a string array → metadata.extensions.
 * - dbTypesTransformPass renders an Elixir list literal in options (no quotes),
 *   treating each string as an Elixir module name (e.g., MyExt.One).
 *
 * USAGE NOTES
 * - The provided extension modules must exist on your code path and implement the
 *   required Postgrex extension behaviour for the adapter.
 * - Repo config still uses: `types: MyApp.PostgrexTypes`.
 *
 * DEFAULT TYPES VS PRECOMPILED
 * - `Postgrex.DefaultTypes` cannot include custom extensions. Use a precompiled
 *   module when you need non-default encoders/decoders.
 */
@:native("MyApp.PostgrexTypes")
@:dbTypes("postgrex", "Jason", ["MyExt.One", "MyExt.Two"])
extern class PostgrexTypes {}
