defmodule AdvancedQueries do
  def demonstrate_subquery() do
    active_users_subquery = "subquery(from u in (from u in User, where: u.active == true), select: u)"
    _popular_posts_subquery = "subquery(from p in (from p in Post, where: p.likes > 100 and p.published == true), select: p)"
    "from u in User\n|> where([u], u.id in ^(" <> active_users_subquery <> "))"
  end
  def demonstrate_cte() do
    popular_posts_c_t_e = "with_cte(\"popular_posts\", as: ^popular_posts_query)"
    recursive_categories_c_t_e = "with_cte(\"recursive_categories\", as: ^categories_with_hierarchy_query)"
    "from u in User\n|> " <> popular_posts_c_t_e <> "\n|> " <> recursive_categories_c_t_e <> "\n|> select([u], u)"
  end
  def demonstrate_window_functions() do
    row_number = "over(row_number(), partition_by: u.department_id, order_by: [desc: u.salary])"
    rank = "over(rank(), partition_by: s.category, order_by: [desc: s.score])"
    dense_rank = "over(dense_rank(), order_by: [asc: s.created_at])"
    "from u in User\n|> select([u], %{id: u.id, row_num: " <> row_number <> ", rank_val: " <> rank <> ", dense_rank_val: " <> dense_rank <> "})"
  end
  def demonstrate_complex_joins() do
    complex_join = "\n|> join(:inner, [q], p in Post, on: u.id == p.user_id)\n|> join(:left, [q, p], c in Comment, on: p.id == c.post_id)\n|> join(:inner, [q, p, c], l in Like, on: c.id == l.comment_id)"
    lateral_join = "|> join_lateral(:inner, [u], p in Post, on: u.id == p.user_id)"
    "from u in User" <> complex_join <> "\n" <> lateral_join <> "\n|> select([u, p, c, l], %{user: u, post: p, comment: c, like: l})"
  end
  def demonstrate_multi_transactions() do
    ("Multi.new()\n|> Multi.insert(:user, User.changeset(%User{}, %{name: \"John\", email: \"john@example.com\"}))\n|> Multi.run(:send_email, fn repo, changes -> fn repo, %{user: user} -> EmailService.send_welcome(user) end end)\n|> Multi.update_all(:increment_stats, from s in Stat, where: s.type == \"user_count\", set: [count: fragment(\"? + 1\", s.count)])")
  end
  def demonstrate_advanced_aggregations() do
    group_by_with_having = "|> group_by([q], [q.department_id, q.role])\n|> having([q], avg(salary) > 50000 and count(*) > 5)"
    count_agg = "count(u.id)"
    sum_agg = "sum(u.salary)"
    avg_agg = "avg(u.age)"
    max_agg = "max(u.created_at)"
    min_agg = "min(u.updated_at)"
    "from u in User\n" <> group_by_with_having <> "\n|> select([u], %{count: " <> count_agg <> ", sum: " <> sum_agg <> ", avg: " <> avg_agg <> ", max: " <> max_agg <> ", min: " <> min_agg <> "})"
  end
  def demonstrate_fragments() do
    fragment = "fragment(\"EXTRACT(year FROM ?) = ?\", u.created_at, 2024)"
    full_text_search = "fragment(\"to_tsvector('english', ?) @@ to_tsquery('english', ?)\", p.content, search_term)"
    "from u in User\n|> join(:inner, [u], p in Post, on: p.user_id == u.id)\n|> where([u, p], " <> fragment <> " and " <> full_text_search <> ")\n|> select([u, p], %{user: u, post: p})"
  end
  def demonstrate_preloading() do
    simple_preload = "|> preload([:posts, :profile, :comments])"
    nested_preload = "|> preload([posts: [:comments, :likes], profile: [:avatar], comments: []])"
    "from u in User\n" <> simple_preload <> "\n" <> nested_preload <> "\n|> select([u], u)"
  end
  def demonstrate_complex_query() do
    ("from u in User, as: :user\n|> join(:inner, [q], p in Post, on: u.id == p.user_id)\n|> join(:left, [q, p], c in Comment, on: p.id == c.post_id)\n|> where([u], u.active == true and u.verified == true)\n|> group_by([u], [u.department_id, u.role])\n|> having([u], count(p.id) > 5 and avg(p.likes) > 10)\n|> order_by([u], [desc: u.created_at, asc: u.name])\n|> limit(50)\n|> offset(100)\n|> preload([:profile, :posts])\n|> select([u], %{name: u.name, post_count: count(p.id), avg_likes: avg(p.likes)})")
  end
  def main() do
    Log.trace("=== Advanced Ecto Features Demonstration ===", %{:file_name => "AdvancedQueries.hx", :line_number => 138, :class_name => "AdvancedQueries", :method_name => "main"})
    Log.trace("1. " <> demonstrate_subquery(), %{:file_name => "AdvancedQueries.hx", :line_number => 140, :class_name => "AdvancedQueries", :method_name => "main"})
    Log.trace("2. " <> demonstrate_c_t_e(), %{:file_name => "AdvancedQueries.hx", :line_number => 141, :class_name => "AdvancedQueries", :method_name => "main"})
    Log.trace("3. " <> demonstrate_window_functions(), %{:file_name => "AdvancedQueries.hx", :line_number => 142, :class_name => "AdvancedQueries", :method_name => "main"})
    Log.trace("4. " <> demonstrate_complex_joins(), %{:file_name => "AdvancedQueries.hx", :line_number => 143, :class_name => "AdvancedQueries", :method_name => "main"})
    Log.trace("5. " <> demonstrate_multi_transactions(), %{:file_name => "AdvancedQueries.hx", :line_number => 144, :class_name => "AdvancedQueries", :method_name => "main"})
    Log.trace("6. " <> demonstrate_advanced_aggregations(), %{:file_name => "AdvancedQueries.hx", :line_number => 145, :class_name => "AdvancedQueries", :method_name => "main"})
    Log.trace("7. " <> demonstrate_fragments(), %{:file_name => "AdvancedQueries.hx", :line_number => 146, :class_name => "AdvancedQueries", :method_name => "main"})
    Log.trace("8. " <> demonstrate_preloading(), %{:file_name => "AdvancedQueries.hx", :line_number => 147, :class_name => "AdvancedQueries", :method_name => "main"})
    Log.trace("9. " <> demonstrate_complex_query(), %{:file_name => "AdvancedQueries.hx", :line_number => 148, :class_name => "AdvancedQueries", :method_name => "main"})
    Log.trace("=== Advanced Ecto Features Completed ===", %{:file_name => "AdvancedQueries.hx", :line_number => 150, :class_name => "AdvancedQueries", :method_name => "main"})
  end
end