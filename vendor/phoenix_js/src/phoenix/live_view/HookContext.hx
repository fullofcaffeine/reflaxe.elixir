package phoenix.live_view;

import js.html.DOMElement;

/**
 * Object-shaped payload sent through Phoenix LiveView hook pushEvent.
 *
 * Phoenix's JS API expects a JSON-serializable object payload, not an arbitrary
 * Haxe Dynamic term. `{}` keeps the extern honest while still accepting typed
 * object literals such as `{message: "copied"}`.
 */
typedef HookPayload = {};

/**
 * phoenix.live_view.HookContext (JS)
 *
 * A minimal type for the Phoenix LiveView Hook "this" context.
 *
 * We keep this intentionally small and only model the fields we use.
 * All interaction with this context is considered a boundary integration point.
 */
typedef HookContext = {
  var el: DOMElement;
  @:optional var pushEvent: (event: String, payload: HookPayload) -> Void;
}
