defmodule Main do
  require Ecto.Query
  def main() do
    lambda_arg_t2()
  end
  def lambda_arg_t2() do
    query = Ecto.Query.from(u in "users")
    filter_val = "alice"
    q2 = if (Kernel.is_nil(filter_val)) do
      Ecto.Query.where(query, [t], is_nil(t.name))
    else
      Ecto.Query.where(query, [t], t.name == ^(filter_val))
    end
    _xs = Enum.map([1, 2, 3], fn t2 -> t2 + 1 end)
    q2
  end
end
