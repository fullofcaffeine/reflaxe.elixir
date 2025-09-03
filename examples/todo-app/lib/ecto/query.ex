defmodule Query do
  def from(schema) do
    query = Ecto.Query.from(schema)
    this1 = query
    this1
  end
  def where_all(query, conditions) do
    elixir_query = Enum.reduce(Map.to_list(conditions), query, fn {field, value}, acc -> Ecto.Query.where(acc, [{field}: value]) end)
    this1 = elixir_query
    this1
  end
end