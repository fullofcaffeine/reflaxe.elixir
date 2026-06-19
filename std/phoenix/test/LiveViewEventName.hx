package phoenix.test;

/**
 * Typed token for app-owned LiveView event names in tests.
 *
 * WHAT
 * - `LiveViewEventName<TEvent>` is a Haxe-only wrapper around a Phoenix event name.
 *
 * WHY
 * - Phoenix events are strings at runtime, but app tests often repeat the same event
 *   names used by templates and `handleEvent` branches.
 * - Wrapping those names in a token lets test helpers say "this argument is an app
 *   event" instead of "this is any random string".
 *
 * HOW
 * - The generated Elixir still receives the plain string event name.
 * - The type parameter is a compile-time marker only. It does not exist at runtime.
 * - Prefer passing values from an app event registry enum abstract, especially one
 *   already marked with `@:phxEventNames` for HXX strict event checking.
 *
 * EXAMPLE
 * ```haxe
 * @:phxEventNames
 * enum abstract CounterEvent(String) to String {
 *   var Increment = "increment";
 * }
 *
 * var event = LiveViewEventName.of(CounterEvent.Increment);
 * view = LiveViewTest.render_click_event(view, event);
 * ```
 */
abstract LiveViewEventName<TEvent>(String) to String {
	/**
	 * Build a typed event token from an app-owned event value.
	 */
	public static inline function of<TEvent>(event:TEvent):LiveViewEventName<TEvent> {
		return cast event;
	}

	/**
	 * Escape hatch for dynamic event names.
	 *
	 * Prefer `of(MyEvent.SomeEvent)` for handwritten tests. Use `unsafe(...)` when the
	 * event name intentionally comes from runtime data or legacy stringly-typed code.
	 */
	public static inline function unsafe<TEvent>(eventName:String):LiveViewEventName<TEvent> {
		return cast eventName;
	}
}
