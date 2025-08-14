defmodule UserQueries do
  use Bitwise
  @moduledoc """
  UserQueries module generated from Haxe
  
  
 * Query compiler test case
 * Tests Ecto query DSL compilation
 
  """

  # Static functions
  @doc "Function get_all_users"
  @spec get_all_users() :: term()
  def get_all_users() do
    UserQueries.from("users", "u", %{select: "u"})
  end

  @doc "Function get_active_users"
  @spec get_active_users() :: term()
  def get_active_users() do
    UserQueries.from("users", "u", %{where: %{active: true}, select: "u"})
  end

  @doc "Function get_users_by_age"
  @spec get_users_by_age(integer(), integer()) :: term()
  def get_users_by_age(arg0, arg1) do
    UserQueries.from("users", "u", %{where: %{age_gte: arg0, age_lte: arg1}, select: "u"})
  end

  @doc "Function get_recent_users"
  @spec get_recent_users(integer()) :: term()
  def get_recent_users(arg0) do
    UserQueries.from("users", "u", %{order_by: %{created_at: "desc"}, limit: arg0, select: "u"})
  end

  @doc "Function get_users_with_posts"
  @spec get_users_with_posts() :: term()
  def get_users_with_posts() do
    UserQueries.from("users", "u", %{join: %{table: "posts", alias: "p", on: "p.user_id == u.id"}, select: %{user: "u", posts: "p"}})
  end

  @doc "Function get_users_with_optional_profile"
  @spec get_users_with_optional_profile() :: term()
  def get_users_with_optional_profile() do
    UserQueries.from("users", "u", %{left_join: %{table: "profiles", alias: "pr", on: "pr.user_id == u.id"}, select: %{user: "u", profile: "pr"}})
  end

  @doc "Function get_user_post_counts"
  @spec get_user_post_counts() :: term()
  def get_user_post_counts() do
    UserQueries.from("users", "u", %{left_join: %{table: "posts", alias: "p", on: "p.user_id == u.id"}, group_by: "u.id", select: %{user: "u", post_count: "count(p.id)"}})
  end

  @doc "Function get_active_posters"
  @spec get_active_posters(integer()) :: term()
  def get_active_posters(arg0) do
    UserQueries.from("users", "u", %{left_join: %{table: "posts", alias: "p", on: "p.user_id == u.id"}, group_by: "u.id", having: "count(p.id) >= " <> arg0, select: %{user: "u", post_count: "count(p.id)"}})
  end

  @doc "Function get_top_users"
  @spec get_top_users() :: term()
  def get_top_users() do
    subquery = UserQueries.from("posts", "p", %{group_by: "p.user_id", select: %{user_id: "p.user_id", count: "count(p.id)"}})
UserQueries.from("users", "u", %{join: %{table: subquery, alias: "s", on: "s.user_id == u.id"}, where: %{count_gt: 10}, select: "u"})
  end

  @doc "Function get_users_with_associations"
  @spec get_users_with_associations() :: term()
  def get_users_with_associations() do
    UserQueries.from("users", "u", %{preload: ["posts", "profile", "comments"], select: "u"})
  end

  @doc "Function deactivate_old_users"
  @spec deactivate_old_users(integer()) :: term()
  def deactivate_old_users(arg0) do
    UserQueries.from("users", "u", %{where: %{last_login_lt: "ago(" <> arg0 <> ", \"day\")"}, update: %{active: false}})
  end

  @doc "Function delete_inactive_users"
  @spec delete_inactive_users() :: term()
  def delete_inactive_users() do
    UserQueries.from("users", "u", %{where: %{active: false}, delete_all: true})
  end

  @doc "Function search_users"
  @spec search_users(term()) :: term()
  def search_users(arg0) do
    query = UserQueries.from("users", "u", %{select: "u"})
if (arg0.name != nil), do: query = UserQueries.where(query, "u", %{name_ilike: arg0.name}), else: nil
if (arg0.email != nil), do: query = UserQueries.where(query, "u", %{email: arg0.email}), else: nil
if (arg0.min_age != nil), do: query = UserQueries.where(query, "u", %{age_gte: arg0.min_age}), else: nil
query
  end

  @doc "Function from"
  @spec from(String.t(), String.t(), term()) :: term()
  def from(arg0, arg1, arg2) do
    nil
  end

  @doc "Function where"
  @spec where(term(), String.t(), term()) :: term()
  def where(arg0, arg1, arg2) do
    nil
  end

end
