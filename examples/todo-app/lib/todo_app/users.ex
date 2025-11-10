defmodule TodoApp.Users do
  require Ecto.Query
  def list_users(filter) do
    query = Ecto.Query.from(t in User, [])
    query = if (not Kernel.is_nil(filter) and not Kernel.is_nil(filter.name)) do
      _query = Ecto.Query.where(query, [t], t.name == ^("%" <> Kernel.to_string(filter.name) <> "%"))
    else
      query
    end
    query = if (not Kernel.is_nil(filter) and not Kernel.is_nil(filter.email)) do
      _query = Ecto.Query.where(query, [t], t.email == ^("%" <> Kernel.to_string(filter.email) <> "%"))
    else
      query
    end
    query = if (not Kernel.is_nil(filter) and not Kernel.is_nil(filter.is_active)) do
      _query = Ecto.Query.where(query, [t], t.active == ^(filter.is_active))
    else
      query
    end
    TodoApp.Repo.all(query)
  end
  def change_user(user) do
    _this1 = (

          (fn data, params ->
             # Convert incoming keys to snake_case atoms
             snake_params = for {k, v} <- Map.to_list(params), into: %{} do
               key =
                 cond do
                   is_atom(k) -> k
                   true -> String.to_atom(Macro.underscore(to_string(k)))
                 end
               {key, v}
             end
             # Normalize values based on schema types when possible
             normalized_params = for {k, v} <- Map.to_list(snake_params), into: %{} do
               type = data.__struct__.__schema__(:type, k)
               v2 = case {type, v} do
                 # Comma-separated string -> {:array, :string}
                 {{:array, :string}, bin} when is_binary(bin) ->
                   bin
                   |> String.split(",", trim: true)
                   |> Enum.map(&String.trim/1)
                 # String -> integer (when field is :integer)
                 {:integer, bin} when is_binary(bin) ->
                   case Integer.parse(bin) do
                     {int, _} -> int
                     :error -> bin
                   end
                 # String -> boolean ("true"/"false")
                 {:boolean, bin} when is_binary(bin) ->
                   case String.downcase(String.trim(bin)) do
                     "true" -> true
                     "false" -> false
                     _ -> bin
                   end
                 # String -> NaiveDateTime
                 {:naive_datetime, bin} when is_binary(bin) ->
                   case NaiveDateTime.from_iso8601(bin) do
                     {:ok, ndt} -> ndt
                     {:error, _} ->
                       case Date.from_iso8601(bin) do
                         {:ok, d} ->
                           case NaiveDateTime.new(d, ~T[00:00:00]) do
                             {:ok, ndt2} -> ndt2
                             _ -> bin
                           end
                         _ -> bin
                       end
                   end
                 # Empty string -> nil for nullable fields (let validations handle required)
                 {_, bin} when is_binary(bin) and bin == "" -> nil
                 _ -> v
               end
               {k, v2}
             end
             Ecto.Changeset.cast(data, normalized_params, Map.keys(normalized_params))
           end).(user, %{})
        
)
  end
  def get_user(id) do
    user = TodoApp.Repo.get(TodoApp.User, id)
    if (Kernel.is_nil(user)) do
      throw("User not found with id: " <> Kernel.to_string(id))
    end
    user
  end
  def get_user_safe(id) do
    TodoApp.Repo.get(TodoApp.User, id)
  end
  def create_user(attrs) do
    TodoApp.Repo.insert(UserChangeset.changeset(nil, attrs))
  end
  def update_user(user, attrs) do
    TodoApp.Repo.update(UserChangeset.changeset(user, attrs))
  end
  def delete_user(user) do
    TodoApp.Repo.delete(user)
  end
end
