defmodule Main do
  require Ecto.Query
  def main() do
    query = Ecto.Query.from(u in "users")
    filter_val = "alice"
    q2 = if (Kernel.is_nil(filter_val)) do
      Ecto.Query.where(query, [t], is_nil(t.name))
    else
      Ecto.Query.where(query, [t], t.name == ^(filter_val))
    end
    q3 = Ecto.Query.order_by(q2, [t], [asc: t.id])
    q4 = Ecto.Query.preload(q3, [:posts])
    q4
  end
end
