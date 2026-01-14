defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<.form for={@form} :let={f}>
    <span><%= f.id %> (<%= f.name %>) <%= f[:email].errors %></span>
</.form>
"""
  end
  def main() do
    
  end
end
