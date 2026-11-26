defmodule Views do
  def compact(page) do
    "compact #{page.name}"
  end
  def full(page) do
    "full #{page.name}"
  end
end
