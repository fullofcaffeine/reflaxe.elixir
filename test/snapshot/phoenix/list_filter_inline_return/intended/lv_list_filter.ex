defmodule LVListFilter do
  def adjust(selected, tag) do
    ret = selected
    if (Lambda.has(selected, tag)) do
      ret = Lambda.filter(ret, fn t -> t != t end)
      ret
    else
      ret
    end
  end
end
