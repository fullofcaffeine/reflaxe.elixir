package;

import HXX;

/**
 * An unchanged template whose literal hook name is validated against a global
 * `@:phxHookNames` registry. It deliberately does not reference HookName: the
 * regression needs to prove that changing shared registry facts revalidates
 * templates that depend on those facts indirectly.
 */
@:hxx_mode("balanced")
class CacheTemplate {
	public static function render(assigns:{ready:Bool}):String {
		return HXX.hxx('<div id="cache-hook" phx-hook="Known">Ready</div>');
	}
}
