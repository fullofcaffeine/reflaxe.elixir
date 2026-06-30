defmodule MyAppWeb.Main do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def render(assigns) do
    ~H"""
<div class="counter">
          <h1><%= @count %></h1>
        </div>
"""
  end
  def main() do

  end
end
