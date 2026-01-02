package client.extern;

/**
 * PhoenixHook
 *
 * Minimal hook callbacks we use in the todo-app.
 *
 * NOTE: This is a boundary type for JS interop; keep it small and stable.
 */
typedef PhoenixHook = {
  var mounted: Void->Void;
  @:optional var destroyed: Void->Void;
}

