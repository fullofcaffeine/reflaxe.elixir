defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<div>Welcome, <%= @current_user.name %>! (<%= Reflaxe.Elixir.HaxeFloat.to_string(@total_todos) %>)</div>
"""
  end
  def main() do

  end
end
