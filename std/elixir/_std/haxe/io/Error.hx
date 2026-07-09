package haxe.io;

/**
 * Error values used by Haxe IO APIs.
 *
 * The Elixir target owns this enum explicitly so generated code does not rely
 * on the upstream stdlib fallback. Several BEAM-backed IO modules throw and
 * catch these values to report unsupported operations, bounds errors, and
 * non-blocking reads in the normal Haxe shape.
 */
enum Error {
	/**
	 * A non-blocking operation would have blocked.
	 */
	Blocked;

	/**
	 * A numeric IO operation exceeded the supported value range.
	 */
	Overflow;

	/**
	 * A read or write range was outside the target buffer.
	 */
	OutsideBounds;

	/**
	 * Target-specific IO error with the original payload.
	 *
	 * Haxe defines this payload as Dynamic, so the target keeps that public
	 * shape even though new Reflaxe.Elixir APIs avoid Dynamic by default.
	 */
	Custom(e:Dynamic);
}
