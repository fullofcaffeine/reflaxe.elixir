defmodule UserRepository do
  def get_all_users() do
    Repo.all(User)
  end
  def get_user(id) do
    Repo.get(User, id)
  end
  def get_user_bang(id) do
    Repo.get!(User, id)
  end
  def create_user(attrs) do
    changeset = UserChangeset.changeset(nil, attrs)
    Repo.insert(changeset)
  end
  def update_user(user, attrs) do
    changeset = UserChangeset.changeset(user, attrs)
    Repo.update(changeset)
  end
  def delete_user(user) do
    Repo.delete(user)
  end
  def preload_posts(user) do
    Repo.preload(user, ["posts"])
  end
  def count_users() do
    Repo.aggregate(User, "count")
  end
  def get_first_user() do
    Repo.one(User)
  end
end