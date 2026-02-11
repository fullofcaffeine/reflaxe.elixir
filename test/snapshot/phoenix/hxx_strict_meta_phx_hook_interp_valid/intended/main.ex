defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<div id="hook-root" phx-hook={"Ping"}>Connected</div>
"""
  end
  def main() do
    
  end
end
