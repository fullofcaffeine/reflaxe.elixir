defmodule Main do
  def main() do
    _ = test_basic_shadowing()
    _ = test_shadowing_with_intervening_statements()
    _ = test_shadowing_in_if_blocks()
    _ = test_query_builder_pattern()
    _ = test_abstract_constructor_pattern()
    nil
  end
  defp test_basic_shadowing() do
    value = "test"
    nil
  end
  defp test_shadowing_with_intervening_statements() do
    query = "SELECT * FROM users"
    query = this1
    nil
  end
  defp test_shadowing_in_if_blocks() do
    filter = %{:name => "John", :email => "john@example.com", :is_active => true}
    if (not Kernel.is_nil(filter)) do
      query = "SELECT * FROM users"
      query = this1
      if (not Kernel.is_nil(filter.name)) do
        value = "%#{(fn -> filter.name end).()}%"
        query = this2
      end
      if (not Kernel.is_nil(filter.email)) do
        value = "%#{(fn -> filter.email end).()}%"
        query = this3
      end
      if (filter.is_active == true) do
        value = filter.is_active
        query = this4
      end
      nil
    end
  end
  defp test_query_builder_pattern() do
    base_query = build_base_query()
    transformed1 = apply_filter(base_query, "name", "Alice")
    temp1 = nil
    temp1 = transformed1
    base_query = temp1
    transformed2 = apply_filter(base_query, "age", "25")
    temp2 = nil
    temp2 = transformed2
    base_query = temp2
    nil
  end
  defp build_base_query() do
    "SELECT * FROM users"
  end
  defp apply_filter(query, field, value) do
    "#{(fn -> query end).()} WHERE #{(fn -> field end).()} = '#{(fn -> value end).()}'"
  end
  defp test_abstract_constructor_pattern() do
    result = create_abstract_value("test_value")
    nil
  end
  defp create_abstract_value(value) do
    %{:type => "abstract", :value => value}
  end
end
