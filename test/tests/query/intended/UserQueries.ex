defmodule UserQueries do
  @moduledoc """
  Query compiler test case
  Tests Ecto query DSL compilation
  """
  
  import Ecto.Query
  
  @doc "Get all users"
  def get_all_users() do
    from(u in "users",
      select: u)
  end
  
  @doc "Get active users"
  def get_active_users() do
    from(u in "users",
      where: u.active == true,
      select: u)
  end
  
  @doc "Get users by age range"
  def get_users_by_age(min_age, max_age) do
    from(u in "users",
      where: u.age >= ^min_age and u.age <= ^max_age,
      select: u)
  end
  
  @doc "Get recent users with limit"
  def get_recent_users(limit) do
    from(u in "users",
      order_by: [desc: u.created_at],
      limit: ^limit,
      select: u)
  end
  
  @doc "Get users with posts"
  def get_users_with_posts() do
    from(u in "users",
      join: p in "posts", on: p.user_id == u.id,
      select: %{user: u, posts: p})
  end
  
  @doc "Get users with optional profile"
  def get_users_with_optional_profile() do
    from(u in "users",
      left_join: pr in "profiles", on: pr.user_id == u.id,
      select: %{user: u, profile: pr})
  end
  
  @doc "Get user post counts"
  def get_user_post_counts() do
    from(u in "users",
      left_join: p in "posts", on: p.user_id == u.id,
      group_by: u.id,
      select: %{user: u, post_count: count(p.id)})
  end
  
  @doc "Get active posters"
  def get_active_posters(min_posts) do
    from(u in "users",
      left_join: p in "posts", on: p.user_id == u.id,
      group_by: u.id,
      having: count(p.id) >= ^min_posts,
      select: %{user: u, post_count: count(p.id)})
  end
  
  @doc "Get top users using subquery"
  def get_top_users() do
    subquery = from(p in "posts",
      group_by: p.user_id,
      select: %{user_id: p.user_id, count: count(p.id)})
    
    from(u in "users",
      join: s in subquery(subquery), on: s.user_id == u.id,
      where: s.count > 10,
      select: u)
  end
  
  @doc "Get users with associations"
  def get_users_with_associations() do
    from(u in "users",
      preload: [:posts, :profile, :comments],
      select: u)
  end
  
  @doc "Deactivate old users"
  def deactivate_old_users(days) do
    from(u in "users",
      where: u.last_login < ago(^days, "day"),
      update: [set: [active: false]])
  end
  
  @doc "Delete inactive users"
  def delete_inactive_users() do
    from(u in "users",
      where: u.active == false)
    |> Repo.delete_all()
  end
  
  @doc "Search users with dynamic filters"
  def search_users(filters) do
    query = from(u in "users", select: u)
    
    query = if filters[:name] do
      where(query, [u], ilike(u.name, ^filters[:name]))
    else
      query
    end
    
    query = if filters[:email] do
      where(query, [u], u.email == ^filters[:email])
    else
      query
    end
    
    query = if filters[:min_age] do
      where(query, [u], u.age >= ^filters[:min_age])
    else
      query
    end
    
    query
  end
end