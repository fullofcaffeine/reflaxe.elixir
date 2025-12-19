defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<div>
      <p><%= @completed_todos == 0 %></p>
      <p><%= @show_form == true %></p>
    </div>
"""
  end
  def main() do
    
  end
end
