defmodule Main do
  def main() do
    builder = %TableBuilder{}
    struct = %{:columns => []}
    _ = TableBuilder.add_column(builder, struct, "test", "string", %{:nullable => true})
  end
end
