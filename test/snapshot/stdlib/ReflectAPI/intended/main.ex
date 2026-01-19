defmodule Main do
  def main() do
    obj = %{:name => "John", :age => 30, :active => true}
    name = Map.get(obj, "name")
    _ = assert(name == "John", "Field retrieval should work")
    missing = Map.get(obj, "missing")
    _ = assert(Kernel.is_nil(missing), "Missing field should return null")
    updated = Map.put(obj, "age", 31)
    _ = assert(Map.get(updated, "age") == 31, "Field should be updated")
    _ = assert(obj.age == 30, "Original object should be unchanged (immutability)")
    with_email = Map.put(obj, "email", "john@example.com")
    _ = assert(Map.get(with_email, "email") == "john@example.com", "New field should be added")
    fields = Reflect.fields(obj)
    _ = assert(length(fields) == 3, "Should have 3 fields")
    _ = assert((fn -> 
                case Enum.find_index(fields, fn item -> item == "name" end) do
                    nil -> -1
                    idx -> idx
                end
             >= 0 end).(), "Should have 'name' field")
    _ = assert((fn -> 
                case Enum.find_index(fields, fn item -> item == "age" end) do
                    nil -> -1
                    idx -> idx
                end
             >= 0 end).(), "Should have 'age' field")
    _ = assert((fn -> 
                case Enum.find_index(fields, fn item -> item == "active" end) do
                    nil -> -1
                    idx -> idx
                end
             >= 0 end).(), "Should have 'active' field")
    _ = assert(Map.has_key?(obj, "name") == true, "Should have 'name' field")
    _ = assert(Map.has_key?(obj, "missing") == false, "Should not have 'missing' field")
    without_age = Reflect.delete_field(obj, "age")
    _ = assert(Map.has_key?(without_age, "age") == false, "Field should be deleted")
    _ = assert(Map.has_key?(obj, "age") == true, "Original should still have field (immutability)")
    _ = assert(Reflect.is_object(obj) == true, "Object should be detected")
    _ = assert(Reflect.is_object("string") == false, "String should not be object")
    _ = assert(Reflect.is_object(42) == false, "Number should not be object")
    _ = assert(Reflect.is_object([1, 2, 3]) == false, "Array should not be object")
    copied = obj
    _ = assert(Map.get(copied, "name") == "John", "Copy should have same fields")
    _ = assert(Reflect.compare("a", "b") < 0, "a should be less than b")
    _ = assert(Reflect.compare("b", "a") > 0, "b should be greater than a")
    _ = assert(Reflect.compare("same", "same") == 0, "Same strings should be equal")
    _ = assert(Reflect.compare(10, 20) < 0, "10 should be less than 20")
    test_func = fn x, y -> x + y end
    result = Reflect.call_method(nil, test_func, [5, 3])
    _ = assert(result == 8, "Function should be called with arguments")
    calculator_base = 10
    calculator = %{:base => calculator_base, :add => fn x -> calculator_base + x end}
    method_result = Reflect.call_method(calculator, calculator.add, [5])
    _ = assert(method_result == 15, "Method should use object context")
    option = {:some, 42}
    _ = assert(Reflect.is_enum_value(option) == true, "Enum value should be detected")
    _ = assert(Reflect.is_enum_value(obj) == false, "Object should not be enum")
    _ = assert(Reflect.is_enum_value("string") == false, "String should not be enum")
    nil
  end
  defp assert(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: " <> message]
    end
  end
end
