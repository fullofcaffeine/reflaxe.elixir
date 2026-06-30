defmodule MyAppWeb.Main do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def render(assigns) do
    ~H"""
<ul data-testid="items">
            <%= for item <- @items do %><li><%= item.name %></li><% end %>
        </ul>
"""
  end
  def main() do

  end
end
