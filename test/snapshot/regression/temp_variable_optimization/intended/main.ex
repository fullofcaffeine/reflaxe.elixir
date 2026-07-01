defmodule Main do
  def main() do
    _ = test_basic_ternary()
    _ = test_nested_ternary()
    _ = test_ternary_in_function()
  end
  defp test_basic_ternary() do
    config = %{name: "test"}
    _id = if (Reflaxe.Elixir.HaxeFloat.neq(config, nil)) do
      (case config do
        dyn_obj ->
          (case Map.fetch(dyn_obj, "id") do
            {:ok, dyn_value} -> dyn_value
            _ ->
              Map.get(dyn_obj, :id)
          end)
      end)
    else
      "default"
    end
    nil
  end
  defp test_nested_ternary() do
    a = 5
    b = 10
    _result = if (a > 0) do
      if (b > 0), do: "both positive", else: "a positive"
    else
      "a not positive"
    end
    nil
  end
  defp test_ternary_in_function() do
    module = "MyModule"
    args = [1, 2, 3]
    id = nil
    _spec = create_spec(module, args, id)
    nil
  end
  defp create_spec(module, args, id) do
    actual_id = if (not Kernel.is_nil(id)), do: id, else: module
    %{id: actual_id, module: module, args: args}
  end
end
