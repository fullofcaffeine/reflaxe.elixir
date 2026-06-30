defmodule MyAppWeb.Main do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def render(assigns) do
    ~H"""
<div class={"chip " <> (if (assigns.enabled), do: "is-on", else: "is-off")} data-count={@count}>
          <span class="label">Hello</span>
        </div>
"""
  end
  def main() do

  end
end
