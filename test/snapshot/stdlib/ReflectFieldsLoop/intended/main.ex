defmodule Main do
  def main() do
    obj = %{:a => 1, :b => 2, :c => 3}
    fields = Map.keys(obj)
    Enum.each(fields, fn field ->
      Log.trace("Field: #{field}", %{:file_name => "Main.hx", :line_number => 7, :class_name => "Main", :method_name => "main"})
    end)

    data = %{:errors => %{:name => ["Required"], :age => ["Invalid"]}}
    changeset_errors = Map.get(data, String.to_atom("errors"))
    if changeset_errors != nil do
      error_fields = Map.keys(changeset_errors)
      Enum.each(error_fields, fn field ->
        field_errors = Map.get(changeset_errors, field)
        # Process field_errors here
      end)
    end
  end
end