defmodule Users do
  def list_users(filter) do
    if (filter != nil) do
      query = Query.from(User)
      if (filter.name != nil) do
        query = EctoQuery_Impl_.where(query, "name", "%" <> Kernel.to_string(filter.name) <> "%")
      end
      if (filter.email != nil) do
        query = EctoQuery_Impl_.where(query, "email", "%" <> Kernel.to_string(filter.email) <> "%")
      end
      if (filter.is_active != nil) do
        query = EctoQuery_Impl_.where(query, "active", filter.is_active)
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
      throw("User not found with id: " <> Kernel.to_string(id))
    end
    user
  end
  def get_user_safe(id) do
    TodoApp.Repo.get(User, id)
  end
  def create_user(attrs) do
    changeset = UserChangeset.changeset(nil, attrs)
    TodoApp.Repo.insert(changeset)
  end
  def update_user(user, attrs) do
    changeset = UserChangeset.changeset(user, attrs)
    TodoApp.Repo.update(changeset)
  end
  def delete_user(user) do
    TodoApp.Repo.delete(user)
  end
  def search_users(_term) do
    []
  end
  def user_stats() do
    %{:total => 0, :active => 0, :inactive => 0}
  end
end
Users.main()