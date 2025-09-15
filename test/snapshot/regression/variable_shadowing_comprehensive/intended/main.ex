defmodule Main do
  @compile [{:nowarn_unused_function, [{:_test_shadowing_with_intervening_statements, 0}, {:_test_shadowing_in_if_blocks, 0}, {:_test_query_builder_pattern, 0}, {:_test_basic_shadowing, 0}, {:_test_abstract_constructor_pattern, 0}, {:_create_abstract_value, 1}, {:_build_base_query, 0}, {:_apply_filter, 3}]}]

  def main() do
    test_basic_shadowing()
    test_shadowing_with_intervening_statements()
    test_shadowing_in_if_blocks()
    test_query_builder_pattern()
    test_abstract_constructor_pattern()
    Log.trace("All shadowing tests complete", %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "main"})
  end
  defp _test_basic_shadowing() do
    value = "test"
    this1 = value
    Log.trace("Basic shadowing: #{this1}", %{:file_name => "Main.hx", :line_number => 29, :class_name => "Main", :method_name => "testBasicShadowing"})
  end
  defp _test_shadowing_with_intervening_statements() do
    query = "SELECT * FROM users"
    new_query = "#{query} WHERE active = true"
    this1 = new_query
    query = this1
    Log.trace("Query with intervening: #{query}", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "testShadowingWithInterveningStatements"})
  end
  defp _test_shadowing_in_if_blocks() do
    filter = %{:name => "John", :email => "john@example.com", :is_active => true}
    if (filter != nil) do
      query = "SELECT * FROM users"
      this1 = query
      query = this1
      if (Map.get(filter, :name) != nil) do
        value = "%#{filter.name}%"
        new_query = "#{query} WHERE name LIKE '#{value}'"
        this2 = new_query
        query = this2
      end
      if (Map.get(filter, :email) != nil) do
        value = "%#{filter.email}%"
        new_query = "#{query} AND email LIKE '#{value}'"
        this3 = new_query
        query = this3
      end
      if (filter.is_active == true) do
        value = filter.is_active
        new_query = "#{query} AND active = #{value}"
        this4 = new_query
        query = this4
      end
      Log.trace("Complex query: #{query}", %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "testShadowingInIfBlocks"})
    end
  end
  defp _test_query_builder_pattern() do
    base_query = build_base_query()
    transformed1 = apply_filter(base_query, "name", "Alice")
    temp1 = transformed1
    base_query = temp1
    transformed2 = apply_filter(base_query, "age", "25")
    temp2 = transformed2
    base_query = temp2
    Log.trace("Query builder result: #{base_query}", %{:file_name => "Main.hx", :line_number => 96, :class_name => "Main", :method_name => "testQueryBuilderPattern"})
  end
  defp _build_base_query() do
    "SELECT * FROM users"
  end
  defp _apply_filter(query, field, value) do
    "#{query} WHERE #{field} = '#{value}'"
  end
  defp _test_abstract_constructor_pattern() do
    this1 = create_abstract_value("test_value")
    result = this1
    Log.trace("Abstract constructor: #{result}", %{:file_name => "Main.hx", :line_number => 113, :class_name => "Main", :method_name => "testAbstractConstructorPattern"})
  end
  defp _create_abstract_value(value) do
    %{:type => "abstract", :value => value}
  end
end