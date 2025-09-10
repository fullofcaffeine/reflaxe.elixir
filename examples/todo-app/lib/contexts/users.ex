defmodule Users do
  def list_users(_filter) do
    if (filter != nil) do
      query = Ecto.Queryable.to_query(User)
      this1 = nil
      this1 = query
      query = this1
      if (Map.get(filter, :name) != nil) do
        value = "%" <> Kernel.to_string(filter.name) <> "%"
        new_query = (require Ecto.Query; Ecto.Query.where(query, [q], field(q, ^String.to_existing_atom(Macro.underscore("name"))) == ^value))
        this1 = nil
        this1 = new_query
        query = this1
      end
      if (Map.get(filter, :email) != nil) do
        value = "%" <> Kernel.to_string(filter.email) <> "%"
        new_query = (require Ecto.Query; Ecto.Query.where(query, [q], field(q, ^String.to_existing_atom(Macro.underscore("email"))) == ^value))
        this1 = nil
        this1 = new_query
        query = this1
      end
      if (Map.get(filter, :is_active) != nil) do
        value = filter.is_active
        new_query = (require Ecto.Query; Ecto.Query.where(query, [q], field(q, ^String.to_existing_atom(Macro.underscore("active"))) == ^value))
        this1 = nil
        this1 = new_query
        query = this1
      end
      TodoApp.Repo.all(query)
    end
    TodoApp.Repo.all(User)
  end
  def change_user(_user) do
    empty_params = %{}
    this1 = Ecto.Changeset.change(user, empty_params)
    this1
  end
  def main() do
    Log.trace("Users context with User schema compiled successfully!", %{:file_name => "src_haxe/server/contexts/Users.hx", :line_number => 107, :class_name => "contexts.Users", :method_name => "main"})
  end
  def get_user(_id) do
    user = TodoApp.Repo.get(User, id)
    if (user == nil) do
      throw("User not found with id: " <> Kernel.to_string(id))
    end
    user
  end
  def get_user_safe(_id) do
    TodoApp.Repo.get(User, id)
  end
  def create_user(_attrs) do
    changeset = UserChangeset.changeset(nil, attrs)
    TodoApp.Repo.insert(changeset)
  end
  def update_user(_user, _attrs) do
    changeset = UserChangeset.changeset(user, attrs)
    TodoApp.Repo.update(changeset)
  end
  def delete_user(_user) do
    TodoApp.Repo.delete(user)
  end
  def search_users(_term) do
    []
  end
  def user_stats() do
    %{:total => 0, :active => 0, :inactive => 0}
  end
end