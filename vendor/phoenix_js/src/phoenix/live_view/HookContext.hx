package phoenix.live_view;

import js.html.DOMElement;
import phoenix.channels.Payload;

/**
 * Object-shaped payload sent through Phoenix LiveView hook pushEvent.
 *
 * Phoenix's JS API expects a JSON-serializable object payload. Reuse the shared
 * Phoenix payload type so LiveView hooks and Channels can share codecs across
 * the JS and Elixir sides of the app.
 */
typedef HookPayload = Payload;

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
