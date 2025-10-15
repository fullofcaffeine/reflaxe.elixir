package client;

class Boot {
  public static function main() {
    // Minimal hook map to satisfy LiveView
    var hooks: Dynamic = {
      AutoFocus: {
        mounted: function() {
          try {
            untyped __js__("this.el && this.el.focus && this.el.focus()");
          } catch (e: Dynamic) {}
        }
      }
    };
    untyped __js__("window.Hooks = window.Hooks || {0}", hooks);
  }
}

