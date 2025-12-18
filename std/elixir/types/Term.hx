package elixir.types;

/**
 * Term
 *
 * WHAT
 * - Opaque wrapper for an arbitrary Elixir `term()`.
 *
 * WHY
 * - Some boundaries (Phoenix assigns/params, low-level interop, generic tuple/map APIs)
 *   are inherently dynamic in the BEAM ecosystem.
 * - Using `Term` keeps public Haxe APIs precise without exposing `Dynamic` broadly.
 *
 * HOW
 * - `Term` is an abstract over the target term representation.
 * - It is implicitly convertible from/to the underlying value.
 */
abstract Term(Dynamic) from Dynamic to Dynamic {}
