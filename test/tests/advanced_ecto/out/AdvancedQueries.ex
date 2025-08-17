defmodule AdvancedQueries do
  @moduledoc """
    AdvancedQueries module generated from Haxe

     * Advanced Ecto Query Features Demonstration
     *
     * This test showcases complex query compilation capabilities including:
     * - Subqueries with proper binding management
     * - CTEs (Common Table Expressions) with recursive support
     * - Window functions (row_number, rank, dense_rank)
     * - Complex joins with lateral joins
     * - Ecto.Multi transaction composition
     * - Advanced aggregations with HAVING clauses
     * - Fragment support for raw SQL
     *
     * Expected compilation: Elixir module with query functions
     * that generate proper Ecto.Query pipe syntax.
  """

  # Static functions
  @doc """
    Demonstrates subquery compilation

  """
  @spec demonstrate_subquery() :: String.t()
  def demonstrate_subquery() do
    active_users_subquery = "subquery(from u in (from u in User, where: u.active == true), select: u)"
    "subquery(from p in (from p in Post, where: p.likes > 100 and p.published == true), select: p)"
    "from u in User\n|> where([u], u.id in ^(" <> active_users_subquery <> "))"
  end

  @doc """
    Demonstrates CTE compilation

  """
  @spec demonstrate_c_t_e() :: String.t()
  def demonstrate_c_t_e() do
    popular_posts_c_t_e = "with_cte(\"popular_posts\", as: ^popular_posts_query)"
    recursive_categories_c_t_e = "with_cte(\"recursive_categories\", as: ^categories_with_hierarchy_query)"
    "from u in User\n|> " <> popular_posts_c_t_e <> "\n|> " <> recursive_categories_c_t_e <> "\n|> select([u], u)"
  end

  @doc """
    Demonstrates window function compilation

  """
  @spec demonstrate_window_functions() :: String.t()
  def demonstrate_window_functions() do
    row_number = "over(row_number(), partition_by: u.department_id, order_by: [desc: u.salary])"
    rank = "over(rank(), partition_by: s.category, order_by: [desc: s.score])"
    dense_rank = "over(dense_rank(), order_by: [asc: s.created_at])"
    "from u in User\n|> select([u], %{id: u.id, row_num: " <> row_number <> ", rank_val: " <> rank <> ", dense_rank_val: " <> dense_rank <> "})"
  end

  @doc """
    Demonstrates complex join compilation

  """
  @spec demonstrate_complex_joins() :: String.t()
  def demonstrate_complex_joins() do
    complex_join = "\n|> join(:inner, [q], p in Post, on: u.id == p.user_id)\n|> join(:left, [q, p], c in Comment, on: p.id == c.post_id)\n|> join(:inner, [q, p, c], l in Like, on: c.id == l.comment_id)"
    lateral_join = "|> join_lateral(:inner, [u], p in Post, on: u.id == p.user_id)"
    "from u in User" <> complex_join <> "\n" <> lateral_join <> "\n|> select([u, p, c, l], %{user: u, post: p, comment: c, like: l})"
  end

  @doc """
    Demonstrates Ecto.Multi transaction compilation

  """
  @spec demonstrate_multi_transactions() :: String.t()
  def demonstrate_multi_transactions() do
    multi_transaction = "Multi.new()\n|> Multi.insert(:user, User.changeset(%User{}, %{name: \"John\", email: \"john@example.com\"}))\n|> Multi.run(:send_email, fn repo, changes -> fn repo, %{user: user} -> EmailService.send_welcome(user) end end)\n|> Multi.update_all(:increment_stats, from s in Stat, where: s.type == \"user_count\", set: [count: fragment(\"? + 1\", s.count)])"
    multi_transaction
  end

  @doc """
    Demonstrates advanced aggregation compilation

  """
  @spec demonstrate_advanced_aggregations() :: String.t()
  def demonstrate_advanced_aggregations() do
    group_by_with_having = "|> group_by([q], [q.department_id, q.role])\n|> having([q], avg(salary) > 50000 and count(*) > 5)"
    count_agg = "count(u.id)"
    sum_agg = "sum(u.salary)"
    avg_agg = "avg(u.age)"
    max_agg = "max(u.created_at)"
    min_agg = "min(u.updated_at)"
    "from u in User\n" <> group_by_with_having <> "\n|> select([u], %{count: " <> count_agg <> ", sum: " <> sum_agg <> ", avg: " <> avg_agg <> ", max: " <> max_agg <> ", min: " <> min_agg <> "})"
  end

  @doc """
    Demonstrates fragment and raw SQL compilation

  """
  @spec demonstrate_fragments() :: String.t()
  def demonstrate_fragments() do
    fragment = "fragment(\"EXTRACT(year FROM ?) = ?\", u.created_at, 2024)"
    full_text_search = "fragment(\"to_tsvector('english', ?) @@ to_tsquery('english', ?)\", p.content, search_term)"
    "from u in User\n|> join(:inner, [u], p in Post, on: p.user_id == u.id)\n|> where([u, p], " <> fragment <> " and " <> full_text_search <> ")\n|> select([u, p], %{user: u, post: p})"
  end

  @doc """
    Demonstrates preload compilation with nested associations

  """
  @spec demonstrate_preloading() :: String.t()
  def demonstrate_preloading() do
    simple_preload = "|> preload([:posts, :profile, :comments])"
    nested_preload = "|> preload([posts: [:comments, :likes], profile: [:avatar], comments: []])"
    "from u in User\n" <> simple_preload <> "\n" <> nested_preload <> "\n|> select([u], u)"
  end

  @doc """
    Demonstrates complete complex query compilation

  """
  @spec demonstrate_complex_query() :: String.t()
  def demonstrate_complex_query() do
    compiled_query = "from u in User, as: :user\n|> join(:inner, [q], p in Post, on: u.id == p.user_id)\n|> join(:left, [q, p], c in Comment, on: p.id == c.post_id)\n|> where([u], u.active == true and u.verified == true)\n|> group_by([u], [u.department_id, u.role])\n|> having([u], count(p.id) > 5 and avg(p.likes) > 10)\n|> order_by([u], [desc: u.created_at, asc: u.name])\n|> limit(50)\n|> offset(100)\n|> preload([:profile, :posts])\n|> select([u], %{name: u.name, post_count: count(p.id), avg_likes: avg(p.likes)})"
    compiled_query
  end

  @doc """
    Main function that calls all demonstrations

  """
  @spec main() :: nil
  def main() do
    Log.trace("=== Advanced Ecto Features Demonstration ===", %{"fileName" => "AdvancedQueries.hx", "lineNumber" => 138, "className" => "AdvancedQueries", "methodName" => "main"})
    Log.trace("1. " <> AdvancedQueries.demonstrateSubquery(), %{"fileName" => "AdvancedQueries.hx", "lineNumber" => 140, "className" => "AdvancedQueries", "methodName" => "main"})
    Log.trace("2. " <> AdvancedQueries.demonstrateCTE(), %{"fileName" => "AdvancedQueries.hx", "lineNumber" => 141, "className" => "AdvancedQueries", "methodName" => "main"})
    Log.trace("3. " <> AdvancedQueries.demonstrateWindowFunctions(), %{"fileName" => "AdvancedQueries.hx", "lineNumber" => 142, "className" => "AdvancedQueries", "methodName" => "main"})
    Log.trace("4. " <> AdvancedQueries.demonstrateComplexJoins(), %{"fileName" => "AdvancedQueries.hx", "lineNumber" => 143, "className" => "AdvancedQueries", "methodName" => "main"})
    Log.trace("5. " <> AdvancedQueries.demonstrateMultiTransactions(), %{"fileName" => "AdvancedQueries.hx", "lineNumber" => 144, "className" => "AdvancedQueries", "methodName" => "main"})
    Log.trace("6. " <> AdvancedQueries.demonstrateAdvancedAggregations(), %{"fileName" => "AdvancedQueries.hx", "lineNumber" => 145, "className" => "AdvancedQueries", "methodName" => "main"})
    Log.trace("7. " <> AdvancedQueries.demonstrateFragments(), %{"fileName" => "AdvancedQueries.hx", "lineNumber" => 146, "className" => "AdvancedQueries", "methodName" => "main"})
    Log.trace("8. " <> AdvancedQueries.demonstratePreloading(), %{"fileName" => "AdvancedQueries.hx", "lineNumber" => 147, "className" => "AdvancedQueries", "methodName" => "main"})
    Log.trace("9. " <> AdvancedQueries.demonstrateComplexQuery(), %{"fileName" => "AdvancedQueries.hx", "lineNumber" => 148, "className" => "AdvancedQueries", "methodName" => "main"})
    Log.trace("=== Advanced Ecto Features Completed ===", %{"fileName" => "AdvancedQueries.hx", "lineNumber" => 150, "className" => "AdvancedQueries", "methodName" => "main"})
  end

end
