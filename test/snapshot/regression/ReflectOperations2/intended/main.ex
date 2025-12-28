defmodule Main do
  def main() do
    obj = %{:name => "John", :age => 30, :is_active => true, :nested_data => %{:street_address => "123 Main St", :zip_code => "12345"}}
    _has_name = Map.has_key?(obj, "name")
    _has_age = Map.has_key?(obj, "age")
    _has_email = Map.has_key?(obj, "email")
    _has_nested_data = Map.has_key?(obj, "nested_data")
    _name = Map.get(obj, "name")
    _age = Map.get(obj, "age")
    _nested_data = Map.get(obj, "nested_data")
    mutable_obj = %{:x => 10, :y => 20}
    mutable_obj = Map.put(mutable_obj, "z", 30)
    _has_z = Map.has_key?(mutable_obj, "z")
    _z_value = Map.get(mutable_obj, "z")
    deletable_obj = %{:a => 1, :b => 2, :c => 3}
    _ = Reflect.delete_field(deletable_obj, "b")
    _has_b = Map.has_key?(deletable_obj, "b")
    _fields = Reflect.fields(obj)
    _is_obj_object = Reflect.is_object(obj)
    _is_string_object = Reflect.is_object("not an object")
    _is_number_object = Reflect.is_object(42)
    _copied = obj
    nil
  end
end
