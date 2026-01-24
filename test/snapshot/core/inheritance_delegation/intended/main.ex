defmodule Main do
  def main() do
    _ = test_basic_inheritance()
    _ = test_exception_inheritance()
    _ = test_method_override()
  end
  defp test_basic_inheritance() do
    _child = Child.new("Alice", 25)
    nil
  end
  defp test_exception_inheritance() do
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: CustomException.new("Something went wrong!")]
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, CustomException) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp test_method_override() do
    _special = SpecialChild.new("Bob", 30)
    nil
  end
end
