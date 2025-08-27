defmodule UserQueries do
  @moduledoc """
    UserQueries module generated from Haxe

     * Query compiler test case
     * Tests Ecto query DSL compilation
  """

  # Static functions
  @doc "Generated from Haxe getAllUsers"
  def get_all_users() do
    UserQueries.from("users", "u", %{"select" => "u"})
  end

  @doc "Generated from Haxe getActiveUsers"
  def get_active_users() do
    UserQueries.from("users", "u", %{"where" => %{"active" => true}, "select" => "u"})
  end

  @doc "Generated from Haxe getUsersByAge"
  def get_users_by_age(min_age, max_age) do
    UserQueries.from("users", "u", %{"where" => %{"age_gte" => min_age, "age_lte" => max_age}, "select" => "u"})
  end

  @doc "Generated from Haxe getRecentUsers"
  def get_recent_users(limit) do
    UserQueries.from("users", "u", %{"order_by" => %{"created_at" => "desc"}, "limit" => limit, "select" => "u"})
  end

  @doc "Generated from Haxe getUsersWithPosts"
  def get_users_with_posts() do
    UserQueries.from("users", "u", %{"join" => %{"table" => "posts", "alias" => "p", "on" => "p.user_id == u.id"}, "select" => %{"user" => "u", "posts" => "p"}})
  end

  @doc "Generated from Haxe getUsersWithOptionalProfile"
  def get_users_with_optional_profile() do
    UserQueries.from("users", "u", %{"left_join" => %{"table" => "profiles", "alias" => "pr", "on" => "pr.user_id == u.id"}, "select" => %{"user" => "u", "profile" => "pr"}})
  end

  @doc "Generated from Haxe getUserPostCounts"
  def get_user_post_counts() do
    UserQueries.from("users", "u", %{"left_join" => %{"table" => "posts", "alias" => "p", "on" => "p.user_id == u.id"}, "group_by" => "u.id", "select" => %{"user" => "u", "post_count" => "count(p.id)"}})
  end

  @doc "Generated from Haxe getActivePosters"
  def get_active_posters(min_posts) do
    UserQueries.from("users", "u", %{"left_join" => %{"table" => "posts", "alias" => "p", "on" => "p.user_id == u.id"}, "group_by" => "u.id", "having" => "count(p.id) >= " <> to_string(min_posts), "select" => %{"user" => "u", "post_count" => "count(p.id)"}})
  end

  @doc "Generated from Haxe getTopUsers"
  def get_top_users() do
    subquery = UserQueries.from("posts", "p", %{"group_by" => "p.user_id", "select" => %{"user_id" => "p.user_id", "count" => "count(p.id)"}})

    UserQueries.from("users", "u", %{"join" => %{"table" => subquery, "alias" => "s", "on" => "s.user_id == u.id"}, "where" => %{"count_gt" => 10}, "select" => "u"})
  end

  @doc "Generated from Haxe getUsersWithAssociations"
  def get_users_with_associations() do
    UserQueries.from("users", "u", %{"preload" => ["posts", "profile", "comments"], "select" => "u"})
  end

  @doc "Generated from Haxe deactivateOldUsers"
  def deactivate_old_users(days) do
    UserQueries.from("users", "u", %{"where" => %{"last_login_lt" => "ago(" <> to_string(days) <> ", \"day\")"}, "update" => %{"active" => false}})
  end

  @doc "Generated from Haxe deleteInactiveUsers"
  def delete_inactive_users() do
    UserQueries.from("users", "u", %{"where" => %{"active" => false}, "delete_all" => true})
  end

  @doc "Generated from Haxe searchUsers"
  def search_users(filters) do
    query = UserQueries.from("users", "u", %{"select" => "u"})

    if ((filters.name != nil)), do: query = UserQueries.where(query, "u", %{"name_ilike" => filters.name}), else: nil

    if ((filters.email != nil)), do: query = UserQueries.where(query, "u", %{"email" => filters.email}), else: nil

    if ((filters.min_age != nil)), do: query = UserQueries.where(query, "u", %{"age_gte" => filters.min_age}), else: nil

    query
  end

  @doc "Generated from Haxe from"
  def from(_table, _alias_, _opts) do
    nil
  end

  @doc "Generated from Haxe where"
  def where(_query, _alias_, _condition) do
    nil
  end

end
