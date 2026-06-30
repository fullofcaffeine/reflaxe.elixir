defmodule MyAppWeb.Main do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def render(assigns) do
    ~H"""
<div class={"wrap " <> assigns.klass}>
            <h1><%= @count %></h1>

            <%= if @show do %>
                <span class="yes">yes</span>
            <% else %>
                <span class="no">no</span>
            <% end %>

            <ul>
                <%= for item <- @items do %>
                    <li class={"row " <> item.name}><%= item.name %></li>
                <% end %>
            </ul>
        </div>
"""
  end
  def main() do

  end
end
