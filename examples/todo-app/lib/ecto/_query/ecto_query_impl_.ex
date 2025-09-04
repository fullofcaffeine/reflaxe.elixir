defmodule EctoQuery_Impl_ do
  def where(this1, __field, value) do
    new_query = (require Ecto.Query; Ecto.Query.where(this1, [field: ^value]))
    this1 = new_query
    this1
  end
  def order_by(this1, field, direction) do
    new_query = if (direction == "desc") do
  (require Ecto.Query; Ecto.Query.order_by(this1, [desc: ^field]))
else
  (require Ecto.Query; Ecto.Query.order_by(this1, [asc: ^field]))
end
    this1 = new_query
    this1
  end
  def limit(this1, count) do
    new_query = (require Ecto.Query; Ecto.Query.limit(this1, ^count))
    this1 = new_query
    this1
  end
  def offset(this1, count) do
    new_query = (require Ecto.Query; Ecto.Query.offset(this1, ^count))
    this1 = new_query
    this1
  end
end