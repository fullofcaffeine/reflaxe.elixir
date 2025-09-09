defmodule Main do
  def main() do
    test_basic_query()
    test_where_clause()
    test_order_by()
    test_limit_offset()
    test_chained_operations()
    test_where_all()
  end
  defp test_basic_query() do
    _query = Query.from(User)
    Log.trace("Basic query created from User schema", %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "testBasicQuery"})
  end
  defp test_where_clause() do
    query = Query.from(User)
    query = EctoQuery_Impl_.where(query, "active", true)
    Log.trace("Query with where clause for active users", %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "testWhereClause"})
  end
  defp test_order_by() do
    query = Query.from(Post)
    query = EctoQuery_Impl_.order_by(query, "createdAt", "desc")
    Log.trace("Query ordered by createdAt descending", %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "testOrderBy"})
  end
  defp test_limit_offset() do
    query = Query.from(Post)
    query = EctoQuery_Impl_.offset(EctoQuery_Impl_.limit(query, 10), 20)
    Log.trace("Query with limit 10 and offset 20", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "testLimitOffset"})
  end
  defp test_chained_operations() do
    _query = EctoQuery_Impl_.limit(EctoQuery_Impl_.order_by(EctoQuery_Impl_.where(Query.from(User), "role", "admin"), "name", "asc"), 5)
    Log.trace("Chained query operations", %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "testChainedOperations"})
  end
  defp test_where_all() do
    conditions = %{}
    conditions = Map.put(conditions, "active", true)
    conditions = Map.put(conditions, "role", "moderator")
    conditions = Map.put(conditions, "age", 25)
    query = Query.from(User)
    query = Query.where_all(query, conditions)
    Log.trace("Query with multiple where conditions", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "testWhereAll"})
  end
end