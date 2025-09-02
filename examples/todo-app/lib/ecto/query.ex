defmodule Query do
  def from(schema) do
    query = Ecto.Query.from(schema)
    this1 = nil
    this1 = query
    this1
  end
  def where_all(query, conditions) do
    elixir_query = query
    field = Map.keys(conditions)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (field.hasNext()) do
    field = field.next()
    elixir_query = Ecto.Query.where(elixir_query, [field: Map.get(conditions, field)])
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    this1 = nil
    this1 = elixir_query
    this1
  end
end