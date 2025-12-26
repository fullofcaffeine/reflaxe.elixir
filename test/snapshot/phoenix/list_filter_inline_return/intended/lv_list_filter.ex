defmodule LVListFilter do
  def adjust(selected, tag) do
    ret = selected
    ret = if (MyApp.Lambda.has(selected, tag)) do
      MyApp.Lambda.filter(ret, fn t -> String.contains?(String.downcase(t.title), query) or t.description != nil and String.contains?(String.downcase(t.description), query) end)
    else
      ret
    end
    ret
  end
end
