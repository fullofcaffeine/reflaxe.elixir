defmodule Main do
  def main() do
    query = Ecto.Query.from(u in "users")
    q2 = Ecto.Query.order_by(query, [t], [asc: t.inserted_at])
    q3 = Ecto.Query.preload(q2, [:posts, :profile])
    q3
  end
end
