defmodule Main do
  require Ecto.Query
  def main() do
    query = Ecto.Query.from(u in "users")
    _name = "alice"
    like = "%" <> name <> "%"
    q2 = if (Kernel.is_nil(like)) do
      Ecto.Query.where(query, [t], is_nil(t.name))
    else
      Ecto.Query.where(query, [t], t.name == ^(like))
    end
    q2
  end
end
