package phoenix.live_react;

import elixir.types.Term;
import phoenix.types.Assigns;

/**
 * API-faithful declaration for stock `LiveReact.Reload` development assets.
 *
 * The upstream `vite_assets/1` component selects Vite-hosted development
 * assets when configured and preserves its nested application script as the
 * production fallback. PhoenixHx uses this low-level declaration from
 * Haxe-authored root layouts; importing it does not install or replace the
 * upstream runtime.
 */
@:native("LiveReact.Reload")
extern class LiveReactReload {
	/** Render the stock Vite asset wrapper around the default slot. */
	public static function vite_assets<TAssigns>(assigns:Assigns<TAssigns>):Term;
}
