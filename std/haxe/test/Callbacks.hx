package haxe.test;

/**
 * Typed access to ExUnit's per-test lifecycle callbacks.
 *
 * The callback runs in ExUnit's normal `on_exit/1` lifecycle after the current
 * test finishes. This is the appropriate boundary for temporary directories,
 * processes, and other resources created by Haxe-authored tests.
 */
@:native("ExUnit.Callbacks")
extern class Callbacks {
	@:native("on_exit")
	public static function onExit(callback:Void->Void):Void;
}
