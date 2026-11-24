package;

import HXX;

/**
 * A template that uses `<.shared_badge>` by tag name. It does not refer to
 * the shared types file, so Haxe does not type it again when that file
 * changes. The warm build must build it again when the component props change.
 */
@:hxx_mode("balanced")
class CacheSharedPage {
	public static function render(assigns:{ready:Bool}):String {
		return HXX.hxx('<.shared_badge label="Hello"></.shared_badge>');
	}
}
