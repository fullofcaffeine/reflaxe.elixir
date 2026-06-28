package phoenix.live_view;

/**
 * Generic-build entrypoint for generated LiveView event protocol companions.
 *
 * WHAT
 * - Turns a shared `@:liveEventProtocol` enum into a companion type with event
 *   constants plus `encode`/`decode` helpers.
 *
 * WHY
 * - Haxe needs a type reference to make generated static helpers visible during
 *   the same compilation. A typedef such as
 *   `typedef ProfileHookEvents = LiveEventProtocolCompanion<ProfileHookEvent>;`
 *   gives app code an ergonomic companion name while keeping generation
 *   deterministic.
 *
 * HOW
 * - The generic-build macro reads the protocol enum and returns a hidden Haxe
 *   implementation type. The implementation is generated from
 *   `LiveEventProtocolModel`, so later JS push helpers and LiveView dispatchers
 *   can share the same normalized model.
 */
@:genericBuild(phoenix.live_view.macros.LiveEventProtocolCompanionBuilder.build())
class LiveEventProtocolCompanion<T> {}
