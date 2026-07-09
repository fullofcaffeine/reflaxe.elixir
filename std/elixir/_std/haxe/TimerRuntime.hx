package haxe;

import elixir.types.Term;

#if !(macro || (!reflaxe_runtime && !elixir)) /**
 * Internal BEAM callback-cell runtime for `haxe.Timer`.
 */
@:native("Haxe.TimerRuntime")
@:keep
@:noCompletion
class TimerRuntime {
	@:keep
	public static function table():Term {
		return untyped __elixir__('(
            case :ets.whereis(:reflaxe_haxe_timer_callbacks) do
              :undefined ->
                try do
                  :ets.new(:reflaxe_haxe_timer_callbacks, [
                    :named_table,
                    :public,
                    :set,
                    read_concurrency: true
                  ])
                rescue
                  ArgumentError -> :ets.whereis(:reflaxe_haxe_timer_callbacks)
                end

              table ->
                table
            end
        )');
	}

	@:keep
	public static function create():Term {
		return untyped __elixir__('(
            table = Haxe.TimerRuntime.table()
            ref = make_ref()
            :ets.insert(table, {ref, nil})
            ref
        )');
	}

	@:keep
	public static function storeCallback(ref:Term, callback:Void->Void):Void {
		untyped __elixir__('(
            if {0} != nil do
              :ets.insert(Haxe.TimerRuntime.table(), {{0}, {1}})
            end
            :ok
        )', ref, callback);
	}

	@:keep
	public static function get(ref:Term, fallback:Void->Void):Void->Void {
		return untyped __elixir__('(
            case {0} do
              nil ->
                {1}

              ref ->
                case :ets.lookup(Haxe.TimerRuntime.table(), ref) do
                  [{^ref, callback}] when is_function(callback, 0) -> callback
                  _ -> {1}
                end
            end
        )', ref, fallback);
	}

	@:keep
	public static function invoke(ref:Term, fallback:Void->Void):Void {
		untyped __elixir__('Haxe.TimerRuntime.get({0}, {1}).()', ref, fallback);
	}

	@:keep
	public static function invoke_default(timer:Timer):Void {
		untyped __elixir__('(
            receiver = {0}
            runtime_module = Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__)
            apply(runtime_module, :run, [receiver])
        )', timer);
	}

	@:keep
	public static function delete(ref:Term):Void {
		untyped __elixir__('(
            if {0} != nil do
              :ets.delete(Haxe.TimerRuntime.table(), {0})
            end
            :ok
        )', ref);
	}
}
#end
