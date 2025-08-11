defmodule TestAdvancedMacros do
  @moduledoc """
  TestAdvancedMacros module generated from Haxe
  
  
 * Test Advanced Ecto Macros Integration
 * 
 * This test validates that the new advanced QueryCompiler functions work correctly
 * and can generate proper Ecto query strings for advanced features.
 
  """

  # Static functions
  @doc "
     * Test subquery compilation
     "
  @spec test_subquery_macro() :: TInst(String,[]).t()
  def test_subquery_macro() do
    "subquery(from active_users in (from u in User, where: u.active == true), select: active_users)"
  end

  @doc "
     * Test CTE compilation
     "
  @spec test_c_t_e_macro() :: TInst(String,[]).t()
  def test_c_t_e_macro() do
    "with_cte("popular_posts", as: ^posts_query)"
  end

  @doc "
     * Test window function compilation
     "
  @spec test_window_macro() :: TInst(String,[]).t()
  def test_window_macro() do
    "over(row_number(), partition_by: u.department_id, order_by: [desc: u.salary])"
  end

  @doc "
     * Test fragment compilation
     "
  @spec test_fragment_macro() :: TInst(String,[]).t()
  def test_fragment_macro() do
    "fragment("EXTRACT(year FROM ?) = ?", u.created_at, 2024)"
  end

  @doc "
     * Test preload compilation
     "
  @spec test_preload_macro() :: TInst(String,[]).t()
  def test_preload_macro() do
    "|> preload([:posts, :profile, :comments])"
  end

  @doc "
     * Test lateral join compilation
     "
  @spec test_lateral_join_macro() :: TInst(String,[]).t()
  def test_lateral_join_macro() do
    "|> join_lateral(:inner, [u], p in Post, on: u.id == p.user_id)"
  end

  @doc "
     * Test union compilation  
     "
  @spec test_union_macro() :: TInst(String,[]).t()
  def test_union_macro() do
    "from u in User, where: u.active
|> union_all(from u in User, where: u.verified)"
  end

  @doc "
     * Test JSON operations compilation
     "
  @spec test_json_macro() :: TInst(String,[]).t()
  def test_json_macro() do
    "json_extract_path(u.metadata, address.city)"
  end

  @doc "
     * Main function that tests all advanced compilation features
     "
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    (
  Log.trace("=== Advanced QueryCompiler Test ===", %{fileName: "TestAdvancedMacros.hx", lineNumber: 116, className: "TestAdvancedMacros", methodName: "main"})
  Log.trace("1. Subquery: " + TestAdvancedMacros.test_subquery_macro(), %{fileName: "TestAdvancedMacros.hx", lineNumber: 118, className: "TestAdvancedMacros", methodName: "main"})
  Log.trace("2. CTE: " + TestAdvancedMacros.test_c_t_e_macro(), %{fileName: "TestAdvancedMacros.hx", lineNumber: 119, className: "TestAdvancedMacros", methodName: "main"})
  Log.trace("3. Window: " + TestAdvancedMacros.test_window_macro(), %{fileName: "TestAdvancedMacros.hx", lineNumber: 120, className: "TestAdvancedMacros", methodName: "main"})
  Log.trace("4. Fragment: " + TestAdvancedMacros.test_fragment_macro(), %{fileName: "TestAdvancedMacros.hx", lineNumber: 121, className: "TestAdvancedMacros", methodName: "main"})
  Log.trace("5. Preload: " + TestAdvancedMacros.test_preload_macro(), %{fileName: "TestAdvancedMacros.hx", lineNumber: 122, className: "TestAdvancedMacros", methodName: "main"})
  Log.trace("6. Lateral Join: " + TestAdvancedMacros.test_lateral_join_macro(), %{fileName: "TestAdvancedMacros.hx", lineNumber: 123, className: "TestAdvancedMacros", methodName: "main"})
  Log.trace("7. Union: " + TestAdvancedMacros.test_union_macro(), %{fileName: "TestAdvancedMacros.hx", lineNumber: 124, className: "TestAdvancedMacros", methodName: "main"})
  Log.trace("8. JSON: " + TestAdvancedMacros.test_json_macro(), %{fileName: "TestAdvancedMacros.hx", lineNumber: 125, className: "TestAdvancedMacros", methodName: "main"})
  Log.trace("=== Advanced QueryCompiler Test Complete ===", %{fileName: "TestAdvancedMacros.hx", lineNumber: 127, className: "TestAdvancedMacros", methodName: "main"})
)
  end

end
