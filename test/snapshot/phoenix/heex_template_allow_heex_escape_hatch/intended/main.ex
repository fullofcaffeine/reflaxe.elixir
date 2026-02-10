defmodule Main do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {Main.Layouts, :app}
  def render(assigns) do
    ~H"""
<div>count: <%= @count %></div>
"""
  end
  def main() do
    
  end
end
