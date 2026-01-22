package phoenix.live_view;

/**
 * phoenix.live_view.Hook (JS)
 *
 * Minimal LiveView hook callbacks used by our examples.
 *
 * NOTE: This is a JS boundary type; keep it small and stable.
 */
typedef Hook = {
  var mounted: Void->Void;
  @:optional var destroyed: Void->Void;
}

