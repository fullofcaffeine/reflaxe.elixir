package haxe;

import haxe.CallStack.StackItem;

/**
 * Native BEAM stack-trace bridge used by `haxe.CallStack` and exceptions.
 *
 * Raw values are contained at this target boundary. Public conversion returns
 * typed Haxe `StackItem` values through the same converter as `CallStack`.
 */
@:dox(hide)
@:noCompletion
class NativeStackTrace {
	@:ifFeature("haxe.NativeStackTrace.exceptionStack")
	static public function saveStack(exception:Any):Void {
		untyped __elixir__('
_ = {0}
saved = Process.get(:__reflaxe_last_stacktrace__)
if Kernel.is_nil(saved) or saved == [] do
  case Process.info(self(), :current_stacktrace) do
    {:current_stacktrace, stacktrace} -> Process.put(:__reflaxe_last_stacktrace__, stacktrace)
    _ -> Process.put(:__reflaxe_last_stacktrace__, [])
  end
end
', exception);
	}

	static public function callStack():Any {
		return untyped __elixir__('
case Process.info(self(), :current_stacktrace) do
  {:current_stacktrace, stacktrace} -> stacktrace
  _ -> []
end
');
	}

	static public function exceptionStack():Any {
		return untyped __elixir__('Process.get(:__reflaxe_last_stacktrace__, [])');
	}

	static public function toHaxe(nativeStackTrace:Any, skip:Int = 0):Array<StackItem> {
		var converted = @:privateAccess CallStack.stackTraceToHaxe(nativeStackTrace);
		if (skip <= 0)
			return converted;
		return cast untyped __elixir__('Enum.drop({0}, {1})', converted, skip);
	}
}
