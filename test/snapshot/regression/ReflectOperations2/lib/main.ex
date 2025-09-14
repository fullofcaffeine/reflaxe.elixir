defmodule Main do
  def main() do
    obj = %{:name => "John", :age => 30, :is_active => true, :nested_data => %{:street_address => "123 Main St", :zip_code => "12345"}}
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
    Log.trace("hasName: " <> Std.string(has_name), %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "main"})
    Log.trace("hasAge: " <> Std.string(has_age), %{:file_name => "Main.hx", :line_number => 49, :class_name => "Main", :method_name => "main"})
    Log.trace("hasEmail: " <> Std.string(has_email), %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "main"})
    Log.trace("hasNestedData: " <> Std.string(has_nested_data), %{:file_name => "Main.hx", :line_number => 51, :class_name => "Main", :method_name => "main"})
    Log.trace("name: " <> name, %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "main"})
    Log.trace("age: " <> Kernel.to_string(age), %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "main"})
    Log.trace("hasZ after setField: " <> Std.string(has_z), %{:file_name => "Main.hx", :line_number => 56, :class_name => "Main", :method_name => "main"})
    Log.trace("zValue: " <> Kernel.to_string(z_value), %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "main"})
    Log.trace("hasB after deleteField: " <> Std.string(has_b), %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "main"})
    Log.trace("fields length: " <> Kernel.to_string(length(fields)), %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "main"})
    Log.trace("isObjObject: " <> Std.string(is_obj_object), %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "main"})
    Log.trace("isStringObject: " <> Std.string(is_string_object), %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "main"})
    Log.trace("isNumberObject: " <> Std.string(is_number_object), %{:file_name => "Main.hx", :line_number => 65, :class_name => "Main", :method_name => "main"})
  end
end