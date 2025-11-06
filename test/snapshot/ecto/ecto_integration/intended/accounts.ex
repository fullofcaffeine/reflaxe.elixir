defmodule Accounts do
  def list_users() do
    MyApp.Repo.all(User)
  end
  def get_user(id) do
    MyApp.Repo.get(MyApp.User, id)
  end
  def create_user(attrs) do
    _ = %user{}
    _ = MyApp.UserChangeset.changeset(user, attrs)
    _ = MyApp.Repo.insert(changeset)
    _
  end
  def update_user(user, attrs) do
    _ = MyApp.UserChangeset.changeset(user, attrs)
    _ = MyApp.Repo.update(changeset)
    _
  end
  def delete_user(user) do
    MyApp.Repo.delete(user)
  end
end
