defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<.inputs_for field={@field} :let={f}>
    <span><%= f.id %> (<%= f.index %>)</span>
</.inputs_for>
"""
  end
  def main() do
    
  end
end
