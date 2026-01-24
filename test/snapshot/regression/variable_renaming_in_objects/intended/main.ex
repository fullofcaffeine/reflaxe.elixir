defmodule Main do
  def main() do
    builder = TableBuilder.new()
    struct = %{:columns => []}
    _ = apply(Map.get(builder, :__reflaxe_class__) || Map.get(builder, :__struct__), :add_column, [builder, struct, "test", "string", %{:nullable => true}])
  end
end
