defmodule Accounts do
  def list_users() do
    Repo.all(User)
  end
  def get_user(id) do
    Repo.get(User, id)
  end
  def create_user(attrs) do
    user = User.new()
    changeset = UserChangeset.changeset(user, attrs)
    Repo.insert(changeset)
  end
  def update_user(user, attrs) do
    changeset = UserChangeset.changeset(user, attrs)
    Repo.update(changeset)
  end
  def delete_user(user) do
    Repo.delete(user)
  end
end