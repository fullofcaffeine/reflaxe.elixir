defmodule Second do
  def render(assigns) do
    if (assigns.on) do
      Views.compact(assigns)
    else
      Views.full(assigns)
    end
  end
end
