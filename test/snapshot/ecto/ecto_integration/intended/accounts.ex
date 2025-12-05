defmodule Accounts do
  def list_users() do
    MyApp.Repo.all(User)
  end
  def get_user(_id) do
    MyApp.Repo.get(MyApp.User, id)
  end
  def create_user(_attrs) do
    user = %user{}
    changeset = MyApp.UserChangeset.changeset(user, attrs)
    _ = MyApp.Repo.insert(changeset)
  end
  def update_user(_user, _attrs) do
    changeset = MyApp.UserChangeset.changeset(user, attrs)
    _ = MyApp.Repo.update(changeset)
  end
  def delete_user(_user) do
    MyApp.Repo.delete(user)
  end
end
