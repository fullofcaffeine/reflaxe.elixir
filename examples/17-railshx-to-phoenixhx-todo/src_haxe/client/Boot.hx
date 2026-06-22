package client;

import js.Syntax;

class Boot {
	public static function main():Void {
		Syntax.code("
      window.Hooks = window.Hooks || {};
      window.Hooks.PhoenixHxTodoFocus = {
        mounted() {
          const target = this.el.querySelector('[data-phoenixhx-autofocus]');
          if (target) target.focus();
        },
        updated() {
          const target = this.el.querySelector('[data-phoenixhx-autofocus]');
          if (target && document.activeElement === document.body) target.focus();
        }
      };
    ");
	}
}
