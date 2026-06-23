defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<div>
  <p>Welcome, <%= @current_user.name %>!</p>
  <div class="stats">
    <span><%= Reflaxe.Elixir.HaxeFloat.to_string(@total_todos) %></span>
    <span><%= Reflaxe.Elixir.HaxeFloat.to_string(@completed_todos) %></span>
    <span><%= Reflaxe.Elixir.HaxeFloat.to_string(@pending_todos) %></span>
  </div>
  <%= if @show_form do %><div id="form">FORM</div><% end %>
</div>
"""
  end
  def main() do

  end
end
