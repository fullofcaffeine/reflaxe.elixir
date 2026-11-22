package;

import HXX;

/**
 * An unchanged template that uses `<.cache_card>`. It does not refer to the
 * component or to its props, so Haxe does not type it again when the props
 * change.
 */
@:hxx_mode("balanced")
class CacheCardPage {
	public static function render(assigns:{ready:Bool}):String {
		return HXX.hxx('<.cache_card title="Hello">Hi</.cache_card>');
	}
}
