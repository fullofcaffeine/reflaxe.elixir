defmodule MyAppWeb.Main do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def render(assigns) do
    ~H"""
    <div class="root">
                <%= if @show do %><span class="yes">Yes</span><% else %><span class="no">No</span><% end %>
                <ul>
                    <%= for item <- @items do %><li><%= item.name %></li><% end %>
                </ul>
            </div>
    """
  end
  def main() do

  end
end
