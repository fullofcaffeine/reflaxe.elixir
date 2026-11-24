package;

import CacheShared.CacheSharedBadgeProps;
import CacheShared.CacheSharedPanelProps;
import HXX;
import phoenix.types.Assigns;

/**
 * A component whose props typedef lives in the shared types file. A template
 * is checked against these props by tag name (`<.shared_badge>`).
 */
@:component
@:hxx_mode("balanced")
class CacheSharedComponents {
	@:component
	public static function sharedBadge(assigns:Assigns<CacheSharedBadgeProps>):String {
		return HXX.hxx('<span class="badge">${assigns.label}</span>');
	}

	@:component
	public static function sharedPanel(assigns:Assigns<CacheSharedPanelProps>):String {
		return HXX.hxx('<section><h3>${assigns.heading}</h3>${assigns.title}</section>');
	}
}
