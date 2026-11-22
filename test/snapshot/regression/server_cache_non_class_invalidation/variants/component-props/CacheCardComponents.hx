package;

import HXX;
import phoenix.types.Assigns;

/**
 * A component whose props typedef lives in another file. A template is
 * checked against these props by tag name (`<.cache_card>`), not through a
 * Haxe reference.
 */
@:component
@:hxx_mode("balanced")
class CacheCardComponents {
	@:component
	public static function cacheCard(assigns:Assigns<CacheCardProps>):String {
		return HXX.hxx('<div><h2>${assigns.title}</h2>${assigns.inner_content}</div>');
	}
}
