package;

/**
 * Snapshot: Sugar annotation @:postgrexTypes("Jason")
 *
 * WHY
 * - Provide a convenient, Phoenix-idiomatic shorthand for generating a precompiled Postgrex
 *   types module without repeating the adapter name in @:dbTypes.
 *
 * WHAT
 * - @:postgrexTypes("Jason") is sugar for @:dbTypes("postgrex", "Jason").
 * - The compiler normalizes this sugar to the generic form and emits:
 *     defmodule MyApp.PostgrexTypes do
 *       Postgrex.Types.define(__MODULE__, [], json: Jason)
 *     end
 * - See intended/my_app/postgrex_types.ex for the expected output.
 *
 * HOW
 * - ModuleBuilder recognizes @:postgrexTypes, sets jsonModule, and internally marks the module
 *   as isDbTypes=true with dbAdapter="postgrex".
 * - The same dbTypesTransformPass then generates the Types.define body.
 *
 * DEFAULT TYPES VS PRECOMPILED
 * - You can alternatively set `types: Postgrex.DefaultTypes` in Repo config to use default encoders.
 * - Use this sugar when you want a typed, Haxe-owned module now and flexibility to add
 *   custom extensions later without refactoring.
 */
@:native("MyApp.PostgrexTypes")
@:postgrexTypes("Jason")
extern class PostgrexTypes {}
