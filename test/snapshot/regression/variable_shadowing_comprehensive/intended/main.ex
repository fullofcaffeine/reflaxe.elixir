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
    nil
  end
  defp test_shadowing_with_intervening_statements() do
    _query = this1
    nil
  end
  defp test_shadowing_in_if_blocks() do
    filter = %{:name => "John", :email => "john@example.com", :is_active => true}
    if (not Kernel.is_nil(filter)) do
      query = this1
      query = if (not Kernel.is_nil(filter.name)) do
        _value = "%#{filter.name}%"
        this2
      else
        query
      end
      query = if (not Kernel.is_nil(filter.email)) do
        _value = "%#{filter.email}%"
        this3
      else
        query
      end
      query = if (filter.is_active == true) do
        _value = filter.is_active
        this4
      else
        query
      end
      nil
    end
  end
  defp test_query_builder_pattern() do
    base_query = build_base_query()
    transformed1 = apply_filter(base_query, "name", "Alice")
    temp1 = transformed1
    base_query = temp1
    transformed2 = apply_filter(base_query, "age", "25")
    temp2 = transformed2
    base_query = temp2
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
    %{:type => "abstract", :value => value}
  end
end
