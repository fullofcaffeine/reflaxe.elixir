defmodule Main do
  def safely(operation) do
    try do
      operation.()
    catch
      :exit, _ ->
        "unavailable"
    end
  end
  def recover(operation, handler) do
    try do
      operation.()
    catch
      :exit, reason ->
        handler.(reason)
    end
  end
  def both(operation) do
    try do
      safely(operation)
    rescue
      _ ->
        "exception"
    end
  end
  def state(operation) do
    result = try do
      operation.()
      result = 2
      result
    catch
      :exit, _ ->
        result = 3
        result
    end
    result
  end
  def ordinary(operation) do
    try do
      operation.()
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {_haxe_catch_value, _} -> "rescued"
        end)
    end
  end
  def aliased(operation) do
    try do
      operation.()
    catch
      :exit, _ ->
        "unavailable"
    end
  end
end
