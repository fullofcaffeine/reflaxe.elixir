defmodule Main do
  def main() do
    obj = %{:a => 1, :b => 2, :c => 3}
    g = 0
    g1 = Reflect.fields(obj)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < acc_g1.length) do
    field = g1[g]
    acc_g = acc_g + 1
    Log.trace("Field: " <> field, %{:fileName => "Main.hx", :lineNumber => 7, :className => "Main", :methodName => "main"})
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    data = %{:errors => %{:name => ["Required"], :age => ["Invalid"]}}
    changeset_errors = Reflect.field(data, "errors")
    if (changeset_errors != nil) do
      g = 0
      g1 = Reflect.fields(changeset_errors)
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, g, :ok}, fn _, {acc_g, acc_g1, acc_g, acc_state} ->
  if (acc_g < acc_g1.length) do
    field = g1[g]
    acc_g = acc_g + 1
    field_errors = Reflect.field(changeset_errors, field)
    if (Std.is(field_errors, Array)) do
      acc_g = 0
      acc_g1 = field_errors
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {acc_g1, acc_g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < acc_g1.length) do
    error = g1[g]
    acc_g = acc_g + 1
    Log.trace("" <> field <> ": " <> Std.string(error), %{:fileName => "Main.hx", :lineNumber => 18, :className => "Main", :methodName => "main"})
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    end
    {:cont, {acc_g, acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_g, acc_state}}
  end
end)
    end
  end
end