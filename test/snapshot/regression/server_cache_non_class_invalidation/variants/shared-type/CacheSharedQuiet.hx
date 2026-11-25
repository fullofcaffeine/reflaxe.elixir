package;

import HXX;

/**
 * A template that uses no component and no registry. No edit of the shared
 * types file can change its output, so a warm build must not build it again.
 */
@:hxx_mode("balanced")
class CacheSharedQuiet {
	public static function render(assigns:{ready:Bool}):String {
		return HXX.hxx('<p class="quiet">Quiet</p>');
	}
}
