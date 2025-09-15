defmodule Main do
  def main() do
    obj = %{:name => "John", :age => 30, :isActive => true, :nested_data => %{:street_address => "123 Main St", :zip_code => "12345"}}
    has_name = Map.has_key?(obj, String.to_atom("name"))
    has_age = Map.has_key?(obj, String.to_atom("age"))
    has_email = Map.has_key?(obj, String.to_atom("email"))
    has_nested_data = Map.has_key?(obj, String.to_atom("nested_data"))
    name = Map.get(obj, String.to_atom("name"))
    age = Map.get(obj, String.to_atom("age"))
    _nested_data = Map.get(obj, String.to_atom("nested_data"))
    mutable_obj = %{:x => 10, :y => 20}
    mutable_obj = Map.put(mutable_obj, String.to_atom("z"), 30)
    has_z = Map.has_key?(mutable_obj, String.to_atom("z"))
    z_value = Map.get(mutable_obj, String.to_atom("z"))
    deletable_obj = %{:a => 1, :b => 2, :c => 3}
    deletable_obj = Map.delete(deletable_obj, String.to_atom("b"))
    has_b = Map.has_key?(deletable_obj, String.to_atom("b"))
    fields = Map.keys(obj)
    is_obj_object = is_map(obj)
    is_string_object = is_map("not an object")
    is_number_object = is_map(42)
    _copied = obj
    Log.trace("hasName: #{has_name}", %{:fileName => "Main.hx", :lineNumber => 48, :className => "Main", :methodName => "main"})
    Log.trace("hasAge: #{has_age}", %{:fileName => "Main.hx", :lineNumber => 49, :className => "Main", :methodName => "main"})
    Log.trace("hasEmail: #{has_email}", %{:fileName => "Main.hx", :lineNumber => 50, :className => "Main", :methodName => "main"})
    Log.trace("hasNestedData: #{has_nested_data}", %{:fileName => "Main.hx", :lineNumber => 51, :className => "Main", :methodName => "main"})
    Log.trace("name: #{name}", %{:fileName => "Main.hx", :lineNumber => 53, :className => "Main", :methodName => "main"})
    Log.trace("age: #{age}", %{:fileName => "Main.hx", :lineNumber => 54, :className => "Main", :methodName => "main"})
    Log.trace("hasZ after setField: #{has_z}", %{:fileName => "Main.hx", :lineNumber => 56, :className => "Main", :methodName => "main"})
    Log.trace("zValue: #{z_value}", %{:fileName => "Main.hx", :lineNumber => 57, :className => "Main", :methodName => "main"})
    Log.trace("hasB after deleteField: #{has_b}", %{:fileName => "Main.hx", :lineNumber => 59, :className => "Main", :methodName => "main"})
    Log.trace("fields length: #{length(fields)}", %{:fileName => "Main.hx", :lineNumber => 61, :className => "Main", :methodName => "main"})
    Log.trace("isObjObject: #{is_obj_object}", %{:fileName => "Main.hx", :lineNumber => 63, :className => "Main", :methodName => "main"})
    Log.trace("isStringObject: #{is_string_object}", %{:fileName => "Main.hx", :lineNumber => 64, :className => "Main", :methodName => "main"})
    Log.trace("isNumberObject: #{is_number_object}", %{:fileName => "Main.hx", :lineNumber => 65, :className => "Main", :methodName => "main"})
  end
end