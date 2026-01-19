defmodule Main do
  require Ecto.Query
  def main() do
    query = Ecto.Query.from(u in "users")
    flag = true
    q2 = if (Kernel.is_nil(flag)) do
      Ecto.Query.where(query, [t], is_nil(t.active))
    else
      Ecto.Query.where(query, [t], t.active == ^(flag))
    end
    q2
  end
end
