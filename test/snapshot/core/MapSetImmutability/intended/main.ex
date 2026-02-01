defmodule Main do
  def main() do
    params = %{}
    params = params |> Map.put("name", "John") |> Map.put("age", 30) |> Map.put("email", "john@example.com")
    _has_email = Map.has_key?(params, "email")
    config = %{}
    _ = config |> Map.put("host", "localhost") |> Map.put("port", "4000") |> Map.put("scheme", "https") |> Map.put("debug", "true")
    data = %{}
    _ = data |> Map.put("item_#{Kernel.to_string(0)}", 0) |> Map.put("item_#{Kernel.to_string(1)}", 10) |> Map.put("item_#{Kernel.to_string(2)}", 20) |> Map.put("item_#{Kernel.to_string(3)}", 30) |> Map.put("item_#{Kernel.to_string(4)}", 40)
    nested = %{}
    inner = %{}
    inner = Map.put(inner, "key", "value")
    _ = Map.put(nested, "section", inner)
    _name = Map.get(params, "name")
    _has_age = Map.has_key?(params, "age")
    _map_had_key_params = Map.has_key?(params, "email")
    _ = Map.delete(params, "email")
    chain_test = %{}
    chain_test = chain_test |> Map.put("a", "1") |> Map.put("b", "2")
    chain_test
  end
end
