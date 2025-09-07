defmodule Query do
  def from(schema) do
    query = (require Ecto.Query; Ecto.Query.from(t in schema))
    this1 = query
    this1
  end
  def where_all(query, conditions) do
    elixir_query = (
Enum.reduce(Map.to_list(conditions), query, fn {field_name, value}, acc ->
                import Ecto.Query
                from(q in acc, where: field(q, ^String.to_existing_atom(field_name)) == ^value)
            end)
)
    this1 = elixir_query
    this1
  end
end