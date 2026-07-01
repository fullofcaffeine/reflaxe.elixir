defmodule PhoenixHxTodo.Accounts do
  require Ecto.Query
  def normalize_email(email) do
    String.downcase(StringTools.ltrim(StringTools.rtrim(email)))
  end
  def normalize_name(name) do
    StringTools.ltrim(StringTools.rtrim(name))
  end
  def get_user(id) do
    PhoenixHxTodo.Repo.get(PhoenixHxTodo.User, id)
  end
  def get_user_by_email(email) do
    normalized_email = normalize_email(email)
    query = if (Kernel.is_nil(normalized_email)) do
      Ecto.Query.where(Ecto.Query.from(t in PhoenixHxTodo.User, []), [t], is_nil(t.email))
    else
      Ecto.Query.where(Ecto.Query.from(t in PhoenixHxTodo.User, []), [t], t.email == ^(normalized_email))
    end
    users = PhoenixHxTodo.Repo.all(query)
    _ = Enum.at(users, 0)
  end
  def get_or_create_demo_user(name, email) do
    normalized_name = normalize_name(name)
    normalized_email = normalize_email(email)
    existing = get_user_by_email(normalized_email)
    if (not Kernel.is_nil(existing)) do
      {:ok, existing}
    else
      data = Kernel.struct(PhoenixHxTodo.User)
      params = %{name: normalized_name, email: normalized_email}
      _ = PhoenixHxTodo.Repo.insert(PhoenixHxTodo.User.changeset(data, params))
    end
  end
end
