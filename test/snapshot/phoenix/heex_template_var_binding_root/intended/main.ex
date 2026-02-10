defmodule Main do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {Main.Layouts, :app}
  def render(assigns) do
    ~H"""
<div class="counter">
          <h1><%= Kernel.to_string(@count) %></h1>
        </div>
"""
  end
  def main() do
    
  end
end
