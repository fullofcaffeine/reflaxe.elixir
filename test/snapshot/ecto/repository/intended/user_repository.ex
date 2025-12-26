defmodule UserRepository do
  def get_all_users() do
    MyApp.Repo.all(User)
  end
  def get_user(id) do
    MyApp.Repo.get(MyApp.User, id)
  end
  def get_user_bang(id) do
    MyApp.Repo.get!(User, id)
  end
  def create_user(attrs) do
    changeset = UserChangeset.changeset(nil, attrs)
    _ = MyApp.Repo.insert(changeset)
  end
  def update_user(user, attrs) do
    changeset = UserChangeset.changeset(user, attrs)
    _ = MyApp.Repo.update(changeset)
  end
  def delete_user(user) do
    MyApp.Repo.delete(user)
  end
  def preload_posts(user) do
    MyApp.Repo.preload(user, ["posts"])
  end
  def count_users() do
    MyApp.Repo.aggregate(User, "count")
  end
  def get_first_user() do
    MyApp.Repo.one(MyApp.User)
  end
end
