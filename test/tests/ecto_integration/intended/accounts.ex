defmodule Accounts do
  @moduledoc """
  The Accounts context
  """

  import Ecto.Query, warn: false
  alias MyApp.Repo

  # Static functions
  @doc "Function list_users"
  @spec list_users() :: Array.t()
  def list_users() do
    Repo.all(User)
  end

  @doc "Function get_user"
  @spec get_user(integer()) :: term()
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc "Function create_user"
  @spec create_user(term()) :: term()
  def create_user(attrs) do
    user = User.new()
    changeset = UserChangeset.changeset(user, attrs)
    Repo.insert(changeset)
  end

  @doc "Function update_user"
  @spec update_user(User.t(), term()) :: term()
  def update_user(user, attrs) do
    changeset = UserChangeset.changeset(user, attrs)
    Repo.update(changeset)
  end

  @doc "Function delete_user"
  @spec delete_user(User.t()) :: term()
  def delete_user(user) do
    Repo.delete(user)
  end

end
