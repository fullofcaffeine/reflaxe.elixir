defmodule Users do
  def list_users(filter) do
    if (filter != nil) do
      query = Query.from(User)
      if (filter.name != nil) do
        query = EctoQuery_Impl_.where(query, "name", "%" <> filter.name <> "%")
      end
      if (filter.email != nil) do
        query = EctoQuery_Impl_.where(query, "email", "%" <> filter.email <> "%")
      end
      if (filter.isActive != nil) do
        query = EctoQuery_Impl_.where(query, "active", filter.isActive)
      end
      TodoApp.Repo.all(query)
    end
    TodoApp.Repo.all(User)
  end
  def change_user(user) do
    empty_params = %{}
    Changeset_Impl_._new(user, empty_params)
  end
  def main() do
    Log.trace("Users context with User schema compiled successfully!", %{:fileName => "src_haxe/server/contexts/Users.hx", :lineNumber => 107, :className => "contexts.Users", :methodName => "main"})
  end
  def get_user(id) do
    user = TodoApp.Repo.get(User, id)
    if (user == nil) do
      throw("User not found with id: " <> id)
    end
    user
  end
  def get_user_safe(id) do
    TodoApp.Repo.get(User, id)
  end
  def create_user(attrs) do
    changeset = UserChangeset.changeset(nil, attrs)
    {:Insert, changeset}
  end
  def update_user(user, attrs) do
    changeset = UserChangeset.changeset(user, attrs)
    {:Update, changeset}
  end
  def delete_user(user) do
    {:Delete, user}
  end
  def search_users(term) do
    []
  end
  defp users_with_posts() do
    []
  end
  def user_stats() do
    %{:total => 0, :active => 0, :inactive => 0}
  end
end