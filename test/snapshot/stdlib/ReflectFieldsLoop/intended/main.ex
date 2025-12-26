defmodule Main do
  def main() do
    obj = %{:a => 1, :b => 2, :c => 3}
    _g = 0
    _ = Reflect.fields(obj)
    _ = Enum.each(g_value, fn _ -> nil end)
    data = %{:errors => %{:name => ["Required"], :age => ["Invalid"]}}
    changeset_errors = Map.get(data, "errors")
    if (not Kernel.is_nil(changeset_errors)) do
      _g = 0
      _ = Reflect.fields(changeset_errors)
      _ = Enum.each(g_value, (fn -> fn field ->
  field_errors = Map.get(changeset_errors, field)
  if (MyApp.Std.is(field_errors, Array)) do
    _g = 0
    _ = field_errors
    _ = Enum.each(g_value, fn _ -> nil end)
  end
end end).())
    end
  end
end
