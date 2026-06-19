defmodule Main do
  require Ecto.Query
  require Ecto.Query
  def explicit_unsafe(search, minimum_age) do
    query = Ecto.Query.from(t in MyApp.User, [])
    query = (require Ecto.Query; Ecto.Query.where(query, fragment("name ILIKE ?", ^search)))
    query = (require Ecto.Query; Ecto.Query.where(query, fragment("age >= ?", ^minimum_age)))
    (require Ecto.Query; Ecto.Query.order_by(query, fragment("CASE WHEN role = 'admin' THEN 0 ELSE 1 END, inserted_at DESC")))
  end
  def compatibility_aliases(search, minimum_age) do
    query = Ecto.Query.from(t in MyApp.User, [])
    query = (require Ecto.Query; Ecto.Query.where(query, fragment("name ILIKE ?", ^search)))
    query = (require Ecto.Query; Ecto.Query.where(query, fragment("age >= ?", ^minimum_age)))
    (require Ecto.Query; Ecto.Query.order_by(query, fragment("CASE WHEN role = 'admin' THEN 0 ELSE 1 END, inserted_at DESC")))
  end
end
