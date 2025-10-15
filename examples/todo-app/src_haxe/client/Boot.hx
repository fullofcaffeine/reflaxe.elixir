package client;

// Phoenix Hook type with only the callbacks we use
typedef PhoenixHook = {
  var mounted: Void->Void;
}

// Typed Hooks registry shape
typedef Hooks = {
  var AutoFocus: PhoenixHook;
  var Ping: PhoenixHook;
}

/**
 * Minimal, typed Phoenix LiveView hook registry for bootstrapping interactivity.
 * Avoids Dynamic on public surfaces per No‑Dynamic policy; uses inline JS only
 * at the boundary to call into the LiveView hook context (this.*).
 */
class Boot {
  public static function main() {
    var hooks: Hooks = {
      AutoFocus: {
        mounted: function(): Void {
          // Focus element if possible (boundary call to hook context)
          js.Syntax.code("this.el && this.el.focus && this.el.focus()");
        }
      },
      Ping: {
        mounted: function(): Void {
          // Validate pushEvent wiring once on mount (non-blocking)
          js.Syntax.code("try { this.pushEvent && this.pushEvent('ping', {}) } catch (_) {} ");
        }
      }
    };

    // Publish hooks for phoenix_app.js to pick up
    js.Syntax.code("window.Hooks = window.Hooks || {0}", hooks);
  }
}
