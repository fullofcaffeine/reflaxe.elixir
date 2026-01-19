defmodule Main do
  require Ecto.Query
  def main() do
    query = Ecto.Query.from(t in "todos")
    i = 3
    b = true
    _q_ne = if (Kernel.is_nil(i)) do
      Ecto.Query.where(query, [t], not is_nil(t.priority))
    else
      Ecto.Query.where(query, [t], t.priority != ^(i))
    end
    _q_lt = Ecto.Query.where(query, [t], t.priority < ^(i))
    _q_lte = Ecto.Query.where(query, [t], t.priority <= ^(i))
    _q_gt = Ecto.Query.where(query, [t], t.priority > ^(i))
    _q_gte = Ecto.Query.where(query, [t], t.priority >= ^(i))
    _q_and = Ecto.Query.where(q, [t], t.completed and ^(b))
    _q_or = Ecto.Query.where(q, [t], t.completed or ^(b))
    q_not = Ecto.Query.where(q, [t], not ^(b))
    q_not
  end
end
