package client;

import js.Syntax;

/**
 * Client entrypoint compiled to JS via Genes (ES modules).
 *
 * Publish a stable `window.Hooks` registry for Phoenix LiveView.
 * Your app can merge additional hooks into this object.
 */
class Boot {
	public static function main():Void {
		Syntax.code("
      window.Hooks = window.Hooks || {};
      window.Hooks.AutoScroll = {
        mounted() { this.el.scrollTop = this.el.scrollHeight; },
        updated() { this.el.scrollTop = this.el.scrollHeight; },
      };
    ");
	}
}
