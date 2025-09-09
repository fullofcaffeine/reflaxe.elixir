defmodule EctoQuery_Impl_ do
  def _new(query) do
    this1 = nil
    this1 = query
    this1
  end
  def where(this1, field_name, value) do
    new_query = (require Ecto.Query; Ecto.Query.where(this1, [q], field(q, ^String.to_existing_atom(Macro.underscore(field_name))) == ^value))
    this1 = nil
    this1 = new_query
    this1
  end
  def order_by(this1, field, direction) do
    new_query = if (direction == "desc") do
  (require Ecto.Query; Ecto.Query.order_by(this1, [q], [desc: field(q, ^String.to_existing_atom(Macro.underscore(field)))]))
else
  (require Ecto.Query; Ecto.Query.order_by(this1, [q], [asc: field(q, ^String.to_existing_atom(Macro.underscore(field)))]))
end
    this1 = nil
    this1 = new_query
    this1
  end
  def limit(this1, count) do
    new_query = (require Ecto.Query; Ecto.Query.limit(this1, ^count))
    this1 = nil
    this1 = new_query
    this1
  end
  def offset(this1, count) do
    new_query = (require Ecto.Query; Ecto.Query.offset(this1, ^count))
    this1 = nil
    this1 = new_query
    this1
  end
  def to_elixir_query(this1) do
    this1
  end
end