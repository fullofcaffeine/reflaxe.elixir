defmodule Haxe.TimerRuntime do
  def table() do
    (
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
            )
  end
  def create() do
    (
                table = Haxe.TimerRuntime.table()
                ref = make_ref()
                :ets.insert(table, {ref, nil})
                ref
            )
  end
  def store_callback(ref, callback) do
    (
                if ref != nil do
                  :ets.insert(Haxe.TimerRuntime.table(), {ref, callback})
                end
                :ok
            )
  end
  def get(ref, fallback) do
    (
                case ref do
                  nil ->
                    fallback

                  ref ->
                    case :ets.lookup(Haxe.TimerRuntime.table(), ref) do
                      [{^ref, callback}] when is_function(callback, 0) -> callback
                      _ -> fallback
                    end
                end
            )
  end
  def invoke(ref, fallback) do
    Haxe.TimerRuntime.get(ref, fallback).()
  end
  def invoke_default(timer) do
    (
                receiver = timer
                runtime_module = Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__)
                apply(runtime_module, :run, [receiver])
            )
  end
  def delete(ref) do
    (
                if ref != nil do
                  :ets.delete(Haxe.TimerRuntime.table(), ref)
                end
                :ok
            )
  end
end
