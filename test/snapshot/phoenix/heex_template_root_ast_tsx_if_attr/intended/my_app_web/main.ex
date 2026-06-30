defmodule MyAppWeb.Main do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def render(assigns) do
    ~H"""
<div data-testid="if-attrs">
            <button :if={@show} class="plain">Visible</button>
            <button :if={@show} class="equals">Also Visible</button>
        </div>
"""
  end
  def main() do

  end
end
