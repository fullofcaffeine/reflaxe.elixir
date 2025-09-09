defmodule Main do
  def main() do
    obj = %{:a => 1, :b => 2, :c => 3}
    g = 0
    g1 = Map.keys(obj)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < length(acc_g1)) do
    field = g1[g]
    acc_g = acc_g + 1
    Log.trace("Field: " <> field, %{:file_name => "Main.hx", :line_number => 7, :class_name => "Main", :method_name => "main"})
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    data = %{:errors => %{:name => ["Required"], :age => ["Invalid"]}}
    changeset_errors = Map.get(data, String.to_atom("errors"))
    if (changeset_errors != nil) do
      g = 0
      g1 = Map.keys(changeset_errors)
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, g, :ok}, fn _, {acc_g1, acc_g, acc_g, acc_state} ->
  if (acc_g < length(acc_g1)) do
    field = g1[g]
    acc_g = acc_g + 1
    field_errors = Map.get(changeset_errors, String.to_atom(field))
    nil
    {:cont, {acc_g1, acc_g, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_g, acc_state}}
  end
end)
    end
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()