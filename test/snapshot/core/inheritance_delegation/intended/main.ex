defmodule Main do
  def main() do
    test_basic_inheritance()
    test_exception_inheritance()
    test_method_override()
  end
  defp test_basic_inheritance() do
    child = Child.new("Alice", 25)
    if (apply(Map.get(child, :__reflaxe_class__) || Map.get(child, :__struct__), :get_name, [child]) != "Alice" or apply(Map.get(child, :__reflaxe_class__) || Map.get(child, :__struct__), :get_age, [child]) != 25) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Parent and child constructors must initialize the same receiver."]
    end
    if (apply(Map.get(child, :__reflaxe_class__) || Map.get(child, :__struct__), :get_description, [child]) != "Parent: Alice, Age: 25") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "An explicit parent call must preserve inherited fields."]
    end
    nil
  end
  defp test_exception_inheritance() do
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: CustomException.new("Something went wrong!")]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {e, _} when is_struct(e, CustomException) or is_map(e) and is_map_key(e, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, e) == CustomException -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp test_method_override() do
    special = SpecialChild.new("Bob", 30)
    if (apply(Map.get(special, :__reflaxe_class__) || Map.get(special, :__struct__), :get_description, [special]) != "Special Parent: Bob, Age: 30") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Each explicit parent call must select the next implementation."]
    end
    parent = special
    if (apply(Map.get(parent, :__reflaxe_class__) || Map.get(parent, :__struct__), :get_description, [parent]) != "Special Parent: Bob, Age: 30") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "A base-typed call must still select the derived override."]
    end
    nil
  end
end
