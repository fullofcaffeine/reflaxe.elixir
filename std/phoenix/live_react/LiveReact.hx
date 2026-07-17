package phoenix.live_react;

import elixir.types.Term;
import phoenix.types.Assigns;

/**
 * API-faithful declaration for the stock `LiveReact` Phoenix component module.
 *
 * `react/1` accepts an open Phoenix assigns map: LiveReact reserves fields such
 * as `id`, `name`, `class`, `socket`, and `ssr`, while forwarding other fields
 * as React props. Application code should put a closed `Assigns<T>` contract in
 * a discoverable app-local `@:component` wrapper when compile-time prop checks
 * are required.
 *
 * The result is an opaque Phoenix rendered term. Importing this declaration
 * neither installs nor replaces the upstream `:live_react` runtime.
 */
@:native("LiveReact")
extern class LiveReact {
	/** Render a stock LiveReact island from Phoenix assigns. */
	public static function react<TAssigns>(assigns:Assigns<TAssigns>):Term;
}
