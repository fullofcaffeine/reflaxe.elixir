defmodule Main do
  def main() do
    obj = %{name: "John", age: 30, active: true}
    name = (case {obj, "name"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
    assert(name == "John", "Field retrieval should work")
    missing = (case {obj, "missing"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
    assert(Reflaxe.Elixir.HaxeFloat.eq(missing, nil), "Missing field should return null")
    updated = (case {obj, "age", 31} do
      {reflect_obj, reflect_field, reflect_value} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true ->
            Map.put(reflect_obj, reflect_field, reflect_value)
          false ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil ->
                Map.put(reflect_obj, reflect_field, reflect_value)
              reflect_atom ->
                Map.put(reflect_obj, reflect_atom, reflect_value)
            end)
        end)
    end)
    assert((fn -> Reflaxe.Elixir.HaxeFloat.eq(((case {updated, "age"} do
        {reflect_obj, reflect_field} ->
          (case Map.fetch(reflect_obj, reflect_field) do
            {:ok, reflect_value} -> reflect_value
            _ ->
              (case (try do
                String.to_existing_atom(reflect_field)
              rescue
                _ ->
                  nil
              end) do
                nil -> nil
                reflect_atom ->
                  Map.get(reflect_obj, reflect_atom)
              end)
          end)
      end)), 31) end).(), "Field should be updated")
    assert(obj.age == 30, "Original object should be unchanged (immutability)")
    with_email = (case {obj, "email", "john@example.com"} do
      {reflect_obj, reflect_field, reflect_value} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true ->
            Map.put(reflect_obj, reflect_field, reflect_value)
          false ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil ->
                Map.put(reflect_obj, reflect_field, reflect_value)
              reflect_atom ->
                Map.put(reflect_obj, reflect_atom, reflect_value)
            end)
        end)
    end)
    assert((fn -> Reflaxe.Elixir.HaxeFloat.eq(((case {with_email, "email"} do
        {reflect_obj, reflect_field} ->
          (case Map.fetch(reflect_obj, reflect_field) do
            {:ok, reflect_value} -> reflect_value
            _ ->
              (case (try do
                String.to_existing_atom(reflect_field)
              rescue
                _ ->
                  nil
              end) do
                nil -> nil
                reflect_atom ->
                  Map.get(reflect_obj, reflect_atom)
              end)
          end)
      end)), "john@example.com") end).(), "New field should be added")
    fields = Reflect.fields(obj)
    assert(length(fields) == 3, "Should have 3 fields")
    assert((case Enum.find_index(fields, fn item -> item == "name" end) do
      nil -> -1
      index -> index
    end) >= 0, "Should have 'name' field")
    assert((case Enum.find_index(fields, fn item -> item == "age" end) do
      nil -> -1
      index -> index
    end) >= 0, "Should have 'age' field")
    assert((case Enum.find_index(fields, fn item -> item == "active" end) do
      nil -> -1
      index -> index
    end) >= 0, "Should have 'active' field")
    assert((case {obj, "name"} do
      {reflect_obj, reflect_field} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true -> true
          false ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> false
              reflect_atom ->
                Map.has_key?(reflect_obj, reflect_atom)
            end)
        end)
    end) == true, "Should have 'name' field")
    assert((case {obj, "missing"} do
      {reflect_obj, reflect_field} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true -> true
          false ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> false
              reflect_atom ->
                Map.has_key?(reflect_obj, reflect_atom)
            end)
        end)
    end) == false, "Should not have 'missing' field")
    {reflaxe_receiver_updated_0, _reflaxe_receiver_value_0} = (case {obj, "age"} do
      {reflect_obj, reflect_field} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true -> {Map.delete(reflect_obj, reflect_field), true}
          false ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> {reflect_obj, false}
              reflect_atom ->
                (case Map.has_key?(reflect_obj, reflect_atom) do
                  true -> {Map.delete(reflect_obj, reflect_atom), true}
                  false -> {reflect_obj, false}
                end)
            end)
        end)
    end)
    without_age = reflaxe_receiver_updated_0
    assert((case {without_age, "age"} do
      {reflect_obj, reflect_field} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true -> true
          false ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> false
              reflect_atom ->
                Map.has_key?(reflect_obj, reflect_atom)
            end)
        end)
    end) == false, "Field should be deleted")
    assert((case {obj, "age"} do
      {reflect_obj, reflect_field} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true -> true
          false ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> false
              reflect_atom ->
                Map.has_key?(reflect_obj, reflect_atom)
            end)
        end)
    end) == true, "Original should still have field (immutability)")
    assert(Reflect.is_object(obj) == true, "Object should be detected")
    assert(Reflect.is_object("string") == false, "String should not be object")
    assert(Reflect.is_object(42) == false, "Number should not be object")
    assert(Reflect.is_object([1, 2, 3]) == false, "Array should not be object")
    copied = obj
    assert((fn -> Reflaxe.Elixir.HaxeFloat.eq(((case {copied, "name"} do
        {reflect_obj, reflect_field} ->
          (case Map.fetch(reflect_obj, reflect_field) do
            {:ok, reflect_value} -> reflect_value
            _ ->
              (case (try do
                String.to_existing_atom(reflect_field)
              rescue
                _ ->
                  nil
              end) do
                nil -> nil
                reflect_atom ->
                  Map.get(reflect_obj, reflect_atom)
              end)
          end)
      end)), "John") end).(), "Copy should have same fields")
    assert(Reflect.compare("a", "b") < 0, "a should be less than b")
    assert(Reflect.compare("b", "a") > 0, "b should be greater than a")
    assert(Reflect.compare("same", "same") == 0, "Same strings should be equal")
    assert(Reflect.compare(10, 20) < 0, "10 should be less than 20")
    test_func = fn x, y -> x + y end
    result = Reflect.call_method(nil, test_func, [5, 3])
    assert(result == 8, "Function should be called with arguments")
    calculator_base = 10
    calculator = %{base: calculator_base, add: fn x -> calculator_base + x end}
    method_result = Reflect.call_method(calculator, calculator.add, [5])
    assert(method_result == 15, "Method should use object context")
    option = {:some, 42}
    assert(Reflect.is_enum_value(option) == true, "Enum value should be detected")
    assert(Reflect.is_enum_value(obj) == false, "Object should not be enum")
    assert(Reflect.is_enum_value("string") == false, "String should not be enum")
    nil
  end
  defp assert(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assertion failed: " <> message]
    end
  end
end
