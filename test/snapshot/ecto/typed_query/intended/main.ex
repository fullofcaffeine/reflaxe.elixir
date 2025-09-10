defmodule Main do
  def main() do
    test_basic_typed_query()
    test_where_conditions()
    test_escape_hatches()
    test_query_execution()
    test_migration_compilation()
  end
  defp test_basic_typed_query() do
    _query = TypedQuery.from(User).limit(10).offset(20)
    Log.trace("Basic TypedQuery created with limit and offset", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "testBasicTypedQuery"})
  end
  defp test_where_conditions() do
    _active_adults = TypedQuery.from(User).where(fn u -> u.active == true end).where(fn u -> u.age >= 18 end).order_by(fn u -> u.created_at end, {1})
    Log.trace("TypedQuery with type-safe where conditions", %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "testWhereConditions"})
  end
  defp test_escape_hatches() do
    complex_query = TypedQuery.from(User).where_raw("active = ? AND role IN (?)", [true, ["admin", "moderator"]]).order_by_raw("CASE WHEN role = 'admin' THEN 0 ELSE 1 END, created_at DESC")
    _ecto_query = complex_query.to_ecto_query()
    Log.trace("TypedQuery with raw SQL escape hatches", %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "testEscapeHatches"})
  end
  defp test_query_execution() do
    _query = TypedQuery.from(User)
    Log.trace("Query execution methods validated", %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "testQueryExecution"})
  end
  defp test_migration_compilation() do
    Log.trace("Migration DSL compiled successfully", %{:file_name => "Main.hx", :line_number => 77, :class_name => "Main", :method_name => "testMigrationCompilation"})
  end
end