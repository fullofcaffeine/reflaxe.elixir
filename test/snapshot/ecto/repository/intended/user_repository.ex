defmodule UserRepository do
  def get_all_users() do
    MyApp.Repo.all(:user)
  end
  def get_user(id) do
    MyApp.Repo.get(:user, id)
  end
  def get_user_bang(id) do
    MyApp.Repo.get!(:user, id)
  end
  def create_user(attrs) do
    changeset = MyApp.UserChangeset.changeset(nil, attrs)
    MyApp.Repo.insert(changeset)
  end
  def update_user(user, attrs) do
    changeset = MyApp.UserChangeset.changeset(user, attrs)
    MyApp.Repo.update(changeset)
  end
  def delete_user(user) do
    MyApp.Repo.delete(user)
  end
  def preload_posts(user) do
    MyApp.Repo.preload(user, ["posts"])
  end
  def count_users() do
    MyApp.Repo.aggregate(:user, "count")
  end
  def get_first_user() do
    MyApp.Repo.one(:user)
  end
end
