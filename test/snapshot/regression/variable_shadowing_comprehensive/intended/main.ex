defmodule Main do
  def main() do
    test_basic_shadowing()
    test_shadowing_with_intervening_statements()
    test_shadowing_in_if_blocks()
    test_query_builder_pattern()
    test_abstract_constructor_pattern()
    nil
  end
  defp test_basic_shadowing() do
    value = "test"
    _ = value
    nil
  end
  defp test_shadowing_with_intervening_statements() do
    query = "SELECT * FROM users"
    new_query = "#{query} WHERE active = true"
    _ = new_query
    nil
  end
  defp test_shadowing_in_if_blocks() do
    filter = %{name: "John", email: "john@example.com", is_active: true}
    query = "SELECT * FROM users"
    query = if (not Kernel.is_nil(filter.name)) do
      value = "%#{filter.name}%"
      new_query = "#{query} WHERE name LIKE '#{value}'"
      new_query
    else
      query
    end
    query = if (not Kernel.is_nil(filter.email)) do
      value = "%#{filter.email}%"
      new_query = "#{query} AND email LIKE '#{value}'"
      new_query
    else
      query
    end
    _ = if (filter.is_active == true) do
      value = filter.is_active
      new_query = "#{query} AND active = #{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
      new_query
    else
      query
    end
    nil
  end
  defp test_query_builder_pattern() do
    base_query = build_base_query()
    transformed1 = apply_filter(base_query, "name", "Alice")
    temp1 = transformed1
    base_query = temp1
    transformed2 = apply_filter(base_query, "age", "25")
    temp2 = transformed2
    _ = temp2
    nil
  end
  defp build_base_query() do
    "SELECT * FROM users"
  end
  defp apply_filter(query, field, value) do
    "#{query} WHERE #{field} = '#{value}'"
  end
  defp test_abstract_constructor_pattern() do
    _result = create_abstract_value("test_value")
    nil
  end
  defp create_abstract_value(value) do
    %{type: "abstract", value: value}
  end
end
