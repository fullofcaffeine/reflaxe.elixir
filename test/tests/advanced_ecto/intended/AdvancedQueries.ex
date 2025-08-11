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
  @doc "
     * Demonstrates subquery compilation
     "
  @spec demonstrate_subquery() :: TInst(String,[]).t()
  def demonstrate_subquery() do
    "from u in User\n|> where([u], u.id in ^(subquery(from u in (from u in User, where: u.active == true), select: u)))"
  end

  @doc "
     * Demonstrates CTE compilation
     "
  @spec demonstrate_c_t_e() :: TInst(String,[]).t()
  def demonstrate_c_t_e() do
    "from u in User\n|> with_cte(\"popular_posts\", as: ^popular_posts_query)\n|> with_cte(\"recursive_categories\", as: ^categories_with_hierarchy_query)\n|> select([u], u)"
  end

  @doc "
     * Demonstrates window function compilation
     "
  @spec demonstrate_window_functions() :: TInst(String,[]).t()
  def demonstrate_window_functions() do
    "from u in User\n|> select([u], %{id: u.id, row_num: over(row_number(), partition_by: u.department_id, order_by: [desc: u.salary]), rank_val: over(rank(), partition_by: s.category, order_by: [desc: s.score]), dense_rank_val: over(dense_rank(), order_by: [asc: s.created_at])})"
  end

  @doc "
     * Demonstrates complex join compilation
     "
  @spec demonstrate_complex_joins() :: TInst(String,[]).t()
  def demonstrate_complex_joins() do
    "from u in User\n|> join(:inner, [q], p in Post, on: u.id == p.user_id)\n|> join(:left, [q, p], c in Comment, on: p.id == c.post_id)\n|> join(:inner, [q, p, c], l in Like, on: c.id == l.comment_id)\n|> join_lateral(:inner, [u], p in Post, on: u.id == p.user_id)\n|> select([u, p, c, l], %{user: u, post: p, comment: c, like: l})"
  end

  @doc "
     * Demonstrates Ecto.Multi transaction compilation
     "
  @spec demonstrate_multi_transactions() :: TInst(String,[]).t()
  def demonstrate_multi_transactions() do
    "Multi.new()\n|> Multi.insert(:user, User.changeset(%User{}, %{name: \"John\", email: \"john@example.com\"}))\n|> Multi.run(:send_email, fn repo, changes -> fn repo, %{user: user} -> EmailService.send_welcome(user) end end)\n|> Multi.update_all(:increment_stats, from s in Stat, where: s.type == \"user_count\", set: [count: fragment(\"? + 1\", s.count)])"
  end

  @doc "
     * Demonstrates advanced aggregation compilation
     "
  @spec demonstrate_advanced_aggregations() :: TInst(String,[]).t()
  def demonstrate_advanced_aggregations() do
    "from u in User\n|> group_by([q], [q.department_id, q.role])\n|> having([q], avg(salary) > 50000 and count(*) > 5)\n|> select([u], %{count: count(u.id), sum: sum(u.salary), avg: avg(u.age), max: max(u.created_at), min: min(u.updated_at)})"
  end

  @doc "
     * Demonstrates fragment and raw SQL compilation
     "
  @spec demonstrate_fragments() :: TInst(String,[]).t()
  def demonstrate_fragments() do
    "from u in User\n|> join(:inner, [u], p in Post, on: p.user_id == u.id)\n|> where([u, p], fragment(\"EXTRACT(year FROM ?) = ?\", u.created_at, 2024) and fragment(\"to_tsvector('english', ?) @@ to_tsquery('english', ?)\", p.content, search_term))\n|> select([u, p], %{user: u, post: p})"
  end

  @doc "
     * Demonstrates preload compilation with nested associations
     "
  @spec demonstrate_preloading() :: TInst(String,[]).t()
  def demonstrate_preloading() do
    "from u in User\n|> preload([:posts, :profile, :comments])\n|> preload([posts: [:comments, :likes], profile: [:avatar], comments: []])\n|> select([u], u)"
  end

  @doc "
     * Demonstrates complete complex query compilation
     "
  @spec demonstrate_complex_query() :: TInst(String,[]).t()
  def demonstrate_complex_query() do
    "from u in User, as: :user\n|> join(:inner, [q], p in Post, on: u.id == p.user_id)\n|> join(:left, [q, p], c in Comment, on: p.id == c.post_id)\n|> where([u], u.active == true and u.verified == true)\n|> group_by([u], [u.department_id, u.role])\n|> having([u], count(p.id) > 5 and avg(p.likes) > 10)\n|> order_by([u], [desc: u.created_at, asc: u.name])\n|> limit(50)\n|> offset(100)\n|> preload([:profile, :posts])\n|> select([u], %{name: u.name, post_count: count(p.id), avg_likes: avg(p.likes)})"
  end

  @doc "
     * Main function that calls all demonstrations
     "
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    # TODO: Implement function body
    nil
  end

end