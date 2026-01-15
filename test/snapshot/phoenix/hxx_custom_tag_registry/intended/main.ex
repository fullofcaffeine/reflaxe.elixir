defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<my-widget enabled={@enabled} variant="primary"></my-widget>
"""
  end
  def main() do
    
  end
end
