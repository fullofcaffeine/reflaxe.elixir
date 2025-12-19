defmodule LVListFilter do
  def adjust(selected, tag) do
    ret = selected
    ret = if (MyApp.Lambda.has(selected, tag)) do
      MyApp.Lambda.filter(ret, fn t -> not Kernel.is_nil(:binary.match(String.downcase(t.title), query)) or t.description != nil and not Kernel.is_nil(:binary.match(String.downcase(t.description), query)) end)
    else
      ret
    end
    ret
  end
end
