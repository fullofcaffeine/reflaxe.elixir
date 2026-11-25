package;

import HXX;

/**
 * A template that uses `<.shared_inline>` by tag name. It does not refer to
 * the component class, so Haxe does not type it again when the props change.
 */
@:hxx_mode("balanced")
class CacheSharedInlinePage {
	public static function render(assigns:{ready:Bool}):String {
		return HXX.hxx('<.shared_inline title="Hello"></.shared_inline>');
	}
}
