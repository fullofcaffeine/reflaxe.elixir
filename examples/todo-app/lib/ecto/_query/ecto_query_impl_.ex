defmodule EctoQuery_Impl_ do
  def _new(query) do
    this1 = nil
    this1 = query
    this1
  end
  def where(this1, field, value) do
    new_query = Ecto.Query.where(this1, [field: value])
    this1 = nil
    this1 = new_query
    this1
  end
  def order_by(this1, field, direction) do
    dir = if (direction == "desc") do
  :desc
else
  :asc
end
    new_query = Ecto.Query.order_by(this1, [dir: field])
    this1 = nil
    this1 = new_query
    this1
  end
  def limit(this1, count) do
    new_query = Ecto.Query.limit(this1, count)
    this1 = nil
    this1 = new_query
    this1
  end
  def offset(this1, count) do
    new_query = Ecto.Query.offset(this1, count)
    this1 = nil
    this1 = new_query
    this1
  end
  def to_elixir_query(this1) do
    this1
  end
end