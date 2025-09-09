package server.infrastructure;

/**
 * Extern wrapper for precompiled Postgrex types.
 *
 * Mirrors the common Phoenix pattern:
 *
 *   defmodule TodoApp.PostgrexTypes do
 *     Postgrex.Types.define(__MODULE__, [], json: Jason)
 *   end
 *
 * The backing Elixir module lives at lib/todo_app/postgrex_types.ex.
 * We expose it here so the app references a typed, Haxe-owned API
 * rather than a “loose” .ex file.
 */
@:native("TodoApp.PostgrexTypes")
@:dbTypes("postgrex", "Jason")
extern class PostgrexTypes {}
