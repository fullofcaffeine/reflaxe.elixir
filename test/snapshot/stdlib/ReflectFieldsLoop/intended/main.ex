defmodule Main do
  def main() do
    obj = %{:a => 1, :b => 2, :c => 3}
    g = 0
    g1 = Reflect.fields(obj)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  field = g1[g]
  g + 1
  Log.trace("Field: " + field, %{:fileName => "Main.hx", :lineNumber => 7, :className => "Main", :methodName => "main"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    data = %{:errors => %{:name => ["Required"], :age => ["Invalid"]}}
    changeset_errors = Reflect.field(data, "errors")
    if (changeset_errors != nil) do
      g = 0
      g1 = Reflect.fields(changeset_errors)
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  field = g1[g]
  g + 1
  field_errors = Reflect.field(changeset_errors, field)
  if (Std.is_of_type(field_errors, Array)) do
    g = 0
    g1 = field_errors
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  error = g1[g]
  g + 1
  Log.trace("" + field + ": " + Std.string(error), %{:fileName => "Main.hx", :lineNumber => 18, :className => "Main", :methodName => "main"})
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    end
  end
end