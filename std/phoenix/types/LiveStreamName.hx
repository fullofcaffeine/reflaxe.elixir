package phoenix.types;

import elixir.types.Atom;

/**
 * Typed LiveView stream name token.
 *
 * WHAT
 * - Models a Phoenix LiveView stream name as `LiveStreamName<TAssigns, TItem>`.
 *
 * WHY
 * - `Phoenix.LiveView.stream/3`, `stream_insert/3`, and `stream_delete/3`
 *   expect a stream name and stream item shape to stay paired.
 * - A typed token catches accidental cross-stream item usage at Haxe compile time
 *   while still emitting ordinary Phoenix stream calls.
 *
 * HOW
 * - Runtime representation is an Elixir atom with zero wrapper cost.
 * - The type parameters are phantom markers for the Haxe type checker.
 * - Prefer generating tokens with `phoenix.LiveStreams.of(MyAssigns)`.
 *
 * EXAMPLES
 * Haxe:
 *   var streams = phoenix.LiveStreams.of(TodoAssigns);
 *   socket = socket.stream(streams.todos, todos);
 *   socket = socket.streamInsert(streams.todos, todo);
 *
 * Elixir:
 *   stream(socket, :todos, todos)
 *   stream_insert(socket, :todos, todo)
 */
abstract LiveStreamName<TAssigns, TItem>(Atom) to Atom {}
