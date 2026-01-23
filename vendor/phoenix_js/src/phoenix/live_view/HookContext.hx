package phoenix.live_view;

import js.html.Element;

/**
 * phoenix.live_view.HookContext (JS)
 *
 * A minimal type for the Phoenix LiveView Hook "this" context.
 *
 * We keep this intentionally small and only model the fields we use.
 * All interaction with this context is considered a boundary integration point.
 */
typedef HookContext = {
  var el: Element;
  @:optional var pushEvent: (event: String, payload: Dynamic) -> Void;
}

