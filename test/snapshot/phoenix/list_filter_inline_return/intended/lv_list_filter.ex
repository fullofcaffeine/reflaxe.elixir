defmodule LVListFilter do
  def adjust(selected, tag) do
    ret = selected
    ret = if (Lambda.has(selected, tag)) do
      Lambda.filter(ret, fn t -> t != t end)
    else
      ret
    end
    ret
  end
end
