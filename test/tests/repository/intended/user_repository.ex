defmodule UserRepository do
  @moduledoc "UserRepository module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe getAllUsers"
  def get_all_users() do
    Repo.all(User)
  end

  @doc "Generated from Haxe getUser"
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc "Generated from Haxe getUserBang"
  def get_user_bang(id) do
    Repo.get!(User, id)
  end

  @doc "Generated from Haxe createUser"
  def create_user(attrs) do
    changeset = UserChangeset.changeset(nil, attrs)

    Repo.insert(changeset)
  end

  @doc "Generated from Haxe updateUser"
  def update_user(user, attrs) do
    changeset = UserChangeset.changeset(user, attrs)

    Repo.update(changeset)
  end

  @doc "Generated from Haxe deleteUser"
  def delete_user(user) do
    Repo.delete(user)
  end

  @doc "Generated from Haxe preloadPosts"
  def preload_posts(user) do
    Repo.preload(user, ["posts"])
  end

  @doc "Generated from Haxe countUsers"
  def count_users() do
    Repo.aggregate(User, "count")
  end

  @doc "Generated from Haxe getFirstUser"
  def get_first_user() do
    Repo.one(User)
  end

end
