defmodule Main do
  defp main() do
    # Build params map with chained puts
    params = %{}
    params = Map.put(params, "name", "John")
    params = Map.put(params, "age", 30)
    params = Map.put(params, "email", "john@example.com")

    has_email = Map.has_key?(params, "email")

    # Build config map
    config = %{}
    config = Map.put(config, "host", "localhost")
    config = Map.put(config, "port", "4000")
    config = Map.put(config, "scheme", "https")
    config = Map.put(config, "debug", "true")

    # Build data map with indexed keys
    data = %{}
    data = Map.put(data, "item_#{0}", 0)
    data = Map.put(data, "item_#{1}", 10)
    data = Map.put(data, "item_#{2}", 20)
    data = Map.put(data, "item_#{3}", 30)
    data = Map.put(data, "item_#{4}", 40)

    # Nested map structure
    nested = %{}
    inner = %{}
    inner = Map.put(inner, "key", "value")
    nested = Map.put(nested, "section", inner)

    # Get and delete operations
    name = Map.get(params, "name")
    has_age = Map.has_key?(params, "age")
    params = Map.delete(params, "email")

    # Chain test - second put doesn't mutate, needs assignment
    chain_test = %{}
    chain_test = Map.put(chain_test, "a", "1")
    chain_test = Map.put(chain_test, "b", "2")
  end
end