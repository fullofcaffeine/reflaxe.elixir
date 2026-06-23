defmodule Main do
  require Ecto.Query
  def typed_query_preload() do
    query = Ecto.Query.from(t in MyApp.User, [])
    query = _ = Ecto.Query.preload(query, [:posts])
    query
  end
  def typed_query_join() do
    query = Ecto.Query.from(t in MyApp.Post, [])
    base_query = query
    join_type = :left
    query = (require Ecto.Query; Ecto.Query.join(base_query, join_type, [t], assoc(t, :user)))
    query
  end
  def typed_query_join_as() do
    query = Ecto.Query.from(t in MyApp.Post, [])
    base_query = query
    binding_alias_atom = String.to_atom("user")
    join_type = :left
    query = (require Ecto.Query; Ecto.Query.join(base_query, join_type, [t], assoc(t, :user), as: binding_alias_atom))
    query
  end
  def main() do

  end
end
