defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<.form for={@ok} :let={f}>
    <span><%= f.id %> (<%= f.name %>) <%= f.data %></span>
</.form>
"""
  end
  def main() do
    
  end
end
