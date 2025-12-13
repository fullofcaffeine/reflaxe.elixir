defmodule Main do
  def main() do
    obj = %{:a => 1, :b => 2, :c => 3}
    _ = Enum.each(obj, (fn -> fn _ ->
  field = Reflect.fields(obj)[0]
  nil
end end).())
    data = %{:errors => %{:name => ["Required"], :age => ["Invalid"]}}
    changeset_errors = Map.get(data, "errors")
    if (not Kernel.is_nil(changeset_errors)) do
      Enum.each(changeset_errors, (fn -> fn item ->
        field = Reflect.fields(changeset_errors)[0]
        field_errors = Map.get(changeset_errors, field)
        if (Std.is(field_errors, Array)) do
          Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {field_errors}, (fn -> fn _, {field_errors} ->
            if (0 < length(field_errors)) do
              error = field_errors[0]
              nil
              {:cont, {field_errors}}
            else
              {:halt, {field_errors}}
            end
          end end).())
        end
      end end).())
    end
  end
end
