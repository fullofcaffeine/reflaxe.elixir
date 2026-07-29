package phoenixhx_live_react_hx;

/**
 * Minimal entrypoint for Haxe→Elixir compilation.
 *
 * This module exists primarily to give the Haxe compiler a stable `--main`.
 * Add your application modules under `phoenixhx_live_react_hx.*` and call them from Elixir as `PhoenixhxLiveReactHx.*`.
 */
@:native("PhoenixhxLiveReactHx.Main")
@:module
class Main {
	public static function main():Void {}
}
