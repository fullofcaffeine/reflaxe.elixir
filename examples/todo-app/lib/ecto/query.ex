defmodule Query do
  def from(schema) do
    query = Ecto.Queryable.to_query(schema)
    this1 = query
    this1
  end
  def where_all(_query, _conditions) do
    this1 = elixir_query
    this1
  end
end