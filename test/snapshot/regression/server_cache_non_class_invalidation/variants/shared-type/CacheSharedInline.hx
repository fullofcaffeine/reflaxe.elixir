package;

import HXX;
import phoenix.types.Assigns;

/**
 * A component whose props are written inside the class, not in the shared
 * types file. An edit of these props is class text. The optional `count`
 * makes the props reach `Int` from the start, so a later change of a prop to
 * `Int` adds no new template fact.
 */
@:component
@:hxx_mode("balanced")
class CacheSharedInline {
	@:component
	public static function sharedInline(assigns:Assigns<{title:String, ?count:Int}>):String {
		return HXX.hxx('<span class="inline">${assigns.title}</span>');
	}
}
