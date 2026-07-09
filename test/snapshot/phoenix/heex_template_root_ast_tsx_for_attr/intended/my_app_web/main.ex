defmodule MyAppWeb.Main do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def render(assigns) do
    ~H"""
    <ul data-testid="rows">
                <%= for item <- @items do %><li class="row-sugar"><%= item.name %></li><% end %>
                <%= for item <- @items do %><li class="row-equals"><%= item.name %></li><% end %>
            </ul>
    """
  end
  def main() do

  end
end
