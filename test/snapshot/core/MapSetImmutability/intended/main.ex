defmodule Main do
  def main() do
    params = %{}
    _ = apply(Map.get(params, :__reflaxe_class__) || Map.get(params, :__struct__), :set, [params, "name", "John"])
    _ = apply(Map.get(params, :__reflaxe_class__) || Map.get(params, :__struct__), :set, [params, "age", 30])
    _ = apply(Map.get(params, :__reflaxe_class__) || Map.get(params, :__struct__), :set, [params, "email", "john@example.com"])
    _has_email = apply(Map.get(params, :__reflaxe_class__) || Map.get(params, :__struct__), :exists, [params, "email"])
    config = %{}
    _ = apply(Map.get(config, :__reflaxe_class__) || Map.get(config, :__struct__), :set, [config, "host", "localhost"])
    _ = apply(Map.get(config, :__reflaxe_class__) || Map.get(config, :__struct__), :set, [config, "port", "4000"])
    _ = apply(Map.get(config, :__reflaxe_class__) || Map.get(config, :__struct__), :set, [config, "scheme", "https"])
    _ = apply(Map.get(config, :__reflaxe_class__) || Map.get(config, :__struct__), :set, [config, "debug", "true"])
    data = %{}
    _ = apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :set, [data, "item_#{Kernel.to_string(0)}", 0])
    _ = apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :set, [data, "item_#{Kernel.to_string(1)}", 10])
    _ = apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :set, [data, "item_#{Kernel.to_string(2)}", 20])
    _ = apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :set, [data, "item_#{Kernel.to_string(3)}", 30])
    _ = apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :set, [data, "item_#{Kernel.to_string(4)}", 40])
    nested = %{}
    inner = %{}
    _ = apply(Map.get(inner, :__reflaxe_class__) || Map.get(inner, :__struct__), :set, [inner, "key", "value"])
    _ = apply(Map.get(nested, :__reflaxe_class__) || Map.get(nested, :__struct__), :set, [nested, "section", inner])
    _name = apply(Map.get(params, :__reflaxe_class__) || Map.get(params, :__struct__), :get, [params, "name"])
    _has_age = apply(Map.get(params, :__reflaxe_class__) || Map.get(params, :__struct__), :exists, [params, "age"])
    _ = apply(Map.get(params, :__reflaxe_class__) || Map.get(params, :__struct__), :remove, [params, "email"])
    chain_test = %{}
    _ = apply(Map.get(chain_test, :__reflaxe_class__) || Map.get(chain_test, :__struct__), :set, [chain_test, "a", "1"])
    _ = apply(Map.get(chain_test, :__reflaxe_class__) || Map.get(chain_test, :__struct__), :set, [chain_test, "b", "2"])
  end
end
