defmodule Main do
  def main() do
    obj = %{:name => "John", :age => 30, :is_active => true, :nested_data => %{:street_address => "123 Main St"}}
    _has_name = Map.has_key?(obj, "name")
    _has_age = Map.has_key?(obj, "age")
    _has_email = Map.has_key?(obj, "email")
    _has_is_active = Map.has_key?(obj, "isActive")
    _has_nested_data = Map.has_key?(obj, "nestedData")
    field_name = "name"
    _has_field_dynamic = Map.has_key?(obj, field_name)
    _has_street_address = Map.has_key?(obj.nested_data, "streetAddress")
    _name_value = Map.get(obj, "name")
    _fields = Reflect.fields(obj)
    obj_without_age = Reflect.delete_field(obj, "age")
    _still_has_age = Map.has_key?(obj_without_age, "age")
    obj_with_email = Map.put(obj, "email", "john@example.com")
    _now_has_email = Map.has_key?(obj_with_email, "email")
    nil
  end
end
