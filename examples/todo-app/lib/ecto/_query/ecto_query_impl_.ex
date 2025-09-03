defmodule EctoQuery_Impl_ do
  def where(this1, field, value) do
    new_query = Ecto.Query.where(this1, [field: value])
    this1 = new_query
    this1
  end
  def order_by(this1, field, direction) do
    new_query = if (direction == "desc") do
  Ecto.Query.order_by(this1, [desc: field])
else
  Ecto.Query.order_by(this1, [asc: field])
end
    this1 = new_query
    this1
  end
  def limit(this1, count) do
    new_query = Ecto.Query.limit(this1, count)
    this1 = new_query
    this1
  end
  def offset(this1, count) do
    new_query = Ecto.Query.offset(this1, count)
    this1 = new_query
    this1
  end
end