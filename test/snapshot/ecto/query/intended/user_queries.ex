defmodule UserQueries do
  def get_all_users() do
    from("users", "u", %{:select => "u"})
  end
  def get_active_users() do
    from("users", "u", %{:where => %{:active => true}, :select => "u"})
  end
  def get_users_by_age(min_age, max_age) do
    from("users", "u", %{:where => %{:age_gte => min_age, :age_lte => max_age}, :select => "u"})
  end
  def get_recent_users(limit) do
    from("users", "u", %{:order_by => %{:created_at => "desc"}, :limit => limit, :select => "u"})
  end
  def get_users_with_posts() do
    from("users", "u", %{:join => %{:table => "posts", :alias => "p", :on => "p.user_id == u.id"}, :select => %{:user => "u", :posts => "p"}})
  end
  def get_users_with_optional_profile() do
    from("users", "u", %{:left_join => %{:table => "profiles", :alias => "pr", :on => "pr.user_id == u.id"}, :select => %{:user => "u", :profile => "pr"}})
  end
  def get_user_post_counts() do
    from("users", "u", %{:left_join => %{:table => "posts", :alias => "p", :on => "p.user_id == u.id"}, :group_by => "u.id", :select => %{:user => "u", :post_count => "count(p.id)"}})
  end
  def get_active_posters(min_posts) do
    from("users", "u", %{:left_join => %{:table => "posts", :alias => "p", :on => "p.user_id == u.id"}, :group_by => "u.id", :having => "count(p.id) >= " <> Kernel.to_string(min_posts), :select => %{:user => "u", :post_count => "count(p.id)"}})
  end
  def get_top_users() do
    subquery = from("posts", "p", %{:group_by => "p.user_id", :select => %{:user_id => "p.user_id", :count => "count(p.id)"}})
    from("users", "u", %{:join => %{:table => subquery, :alias => "s", :on => "s.user_id == u.id"}, :where => %{:count_gt => 10}, :select => "u"})
  end
  def get_users_with_associations() do
    from("users", "u", %{:preload => ["posts", "profile", "comments"], :select => "u"})
  end
  def deactivate_old_users(days) do
    from("users", "u", %{:where => %{:last_login_lt => "ago(" <> Kernel.to_string(days) <> ", \"day\")"}, :update => %{:active => false}})
  end
  def delete_inactive_users() do
    from("users", "u", %{:where => %{:active => false}, :delete_all => true})
  end
  def search_users(filters) do
    query = from("users", "u", %{:select => "u"})
    if (filters.name != nil) do
      query = where(query, "u", %{:name_ilike => filters.name})
    end
    if (filters.email != nil) do
      query = where(query, "u", %{:email => filters.email})
    end
    if (filters.min_age != nil) do
      query = where(query, "u", %{:age_gte => filters.min_age})
    end
    query
  end
  defp from(_table, _alias, _opts) do
    nil
  end
  defp where(_query, _alias, _condition) do
    nil
  end
end