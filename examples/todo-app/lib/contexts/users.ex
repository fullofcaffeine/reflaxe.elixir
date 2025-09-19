defmodule Users do
  def list_users(filter) do
    if (filter != nil) do
      temp_ecto_query = nil
      query = Ecto.Queryable.to_query(User)
      this1 = query
      temp_ecto_query = this1
      query = temp_ecto_query
      if (filter.name != nil) do
        temp_right = nil
        value = "%" <> filter.name.to_string() <> "%"
        new_query = (require Ecto.Query; Ecto.Query.where(query, [q], field(q, ^String.to_existing_atom(Macro.underscore("name"))) == ^value))
        this1 = new_query
        temp_right = this1
        query = temp_right
      end
      if (filter.email != nil) do
        temp_right1 = nil
        value = "%" <> filter.email.to_string() <> "%"
        new_query = (require Ecto.Query; Ecto.Query.where(query, [q], field(q, ^String.to_existing_atom(Macro.underscore("email"))) == ^value))
        this1 = new_query
        temp_right1 = this1
        query = temp_right1
      end
      if (filter.is_active != nil) do
        temp_right2 = nil
        value = filter.is_active
        new_query = (require Ecto.Query; Ecto.Query.where(query, [q], field(q, ^String.to_existing_atom(Macro.underscore("active"))) == ^value))
        this1 = new_query
        temp_right2 = this1
        query = temp_right2
      end
      TodoApp.Repo.all(query)
    end
    TodoApp.Repo.all(User)
  end
  def change_user(user) do
    empty_params = %{}
    this1 = Ecto.Changeset.change(user, empty_params)
    temp_result = this1
    temp_result
  end
  def main() do
    Log.trace("Users context with User schema compiled successfully!", %{:file_name => "src_haxe/server/contexts/Users.hx", :line_number => 107, :class_name => "contexts.Users", :method_name => "main"})
  end
  def get_user(id) do
    user = TodoApp.Repo.get(User, id)
    if (user == nil) do
      throw("User not found with id: " <> id.to_string())
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
  def search_users(term) do
    []
  end
  def user_stats() do
    %{:total => 0, :active => 0, :inactive => 0}
  end
end