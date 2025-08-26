defmodule Accounts do
  @moduledoc """
  The Accounts context
  """

  import Ecto.Query, warn: false
  alias MyApp.Repo

  # Static functions
  @doc "Generated from Haxe list_users"
  def list_users() do
    Enum.all?(Repo, User)
  end

  @doc "Generated from Haxe get_user"
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc "Generated from Haxe create_user"
  def create_user(attrs) do
    user = User.new()

    _changeset = UserChangeset.changeset(user, attrs)

    Repo.insert(changeset)
  end

  @doc "Generated from Haxe update_user"
  def update_user(user, attrs) do
    _changeset = UserChangeset.changeset(user, attrs)

    Repo.update(changeset)
  end

  @doc "Generated from Haxe delete_user"
  def delete_user(user) do
    Repo.delete(user)
  end

end
