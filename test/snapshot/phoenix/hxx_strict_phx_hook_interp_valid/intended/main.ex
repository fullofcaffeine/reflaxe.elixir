defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<div id="hook" phx-hook={"Known"}></div>
"""
  end
  def main() do
    
  end
end
