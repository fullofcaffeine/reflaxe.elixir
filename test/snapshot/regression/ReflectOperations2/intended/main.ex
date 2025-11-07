defmodule Main do
  def main() do
    obj = %{:name => "John", :age => 30, :is_active => true, :nested_data => %{:street_address => "123 Main St", :zip_code => "12345"}}
    has_name = Map.has_key?(obj, "name")
    has_age = Map.has_key?(obj, "age")
    has_email = Map.has_key?(obj, "email")
    has_nested_data = Map.has_key?(obj, "nested_data")
    _name = Map.get(obj, "name")
    _age = Map.get(obj, "age")
    _nested_data = Map.get(obj, "nested_data")
    mutable_obj = %{:x => 10, :y => 20}
    _ = Map.put(mutable_obj, "z", 30)
    has_z = Map.has_key?(mutable_obj, "z")
    _z_value = Map.get(mutable_obj, "z")
    deletable_obj = %{:a => 1, :b => 2, :c => 3}
    _ = Reflect.delete_field(deletable_obj, "b")
    has_b = Map.has_key?(deletable_obj, "b")
    fields = Reflect.fields(obj)
    is_obj_object = Reflect.is_object(obj)
    is_string_object = Reflect.is_object("not an object")
    is_number_object = Reflect.is_object(42)
    _ = Log.trace("hasName: #{(fn -> inspect(has_name) end).()}", %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("hasAge: #{(fn -> inspect(has_age) end).()}", %{:file_name => "Main.hx", :line_number => 49, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("hasEmail: #{(fn -> inspect(has_email) end).()}", %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("hasNestedData: #{(fn -> inspect(has_nested_data) end).()}", %{:file_name => "Main.hx", :line_number => 51, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("name: #{(fn -> name end).()}", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("age: #{(fn -> age end).()}", %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("hasZ after setField: #{(fn -> inspect(has_z) end).()}", %{:file_name => "Main.hx", :line_number => 56, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("zValue: #{(fn -> z_value end).()}", %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("hasB after deleteField: #{(fn -> inspect(has_b) end).()}", %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("fields length: #{(fn -> length(fields) end).()}", %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("isObjObject: #{(fn -> inspect(is_obj_object) end).()}", %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("isStringObject: #{(fn -> inspect(is_string_object) end).()}", %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("isNumberObject: #{(fn -> inspect(is_number_object) end).()}", %{:file_name => "Main.hx", :line_number => 65, :class_name => "Main", :method_name => "main"})
  end
end
