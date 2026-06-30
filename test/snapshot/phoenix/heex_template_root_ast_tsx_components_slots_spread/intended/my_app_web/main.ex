defmodule MyAppWeb.Main do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  import MyAppWeb.CoreComponents
  def render(assigns) do
    ~H"""
<section {@attrs} data-testid="users">
            <.panel title={@title}>
                <:actions>
                    <.button class="btn">New</.button>
                </:actions>

                <ul>
                    <%= for user <- @users do %>
                        <li><%= user.name %></li>
                    <% end %>
                </ul>
            </.panel>

            <Main.Components.badge {@attrs}></Main.Components.badge>
        </section>
"""
  end
  def main() do

  end
end
