defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
    <div>count: <%= @count %></div>
    """
  end
  def main() do

  end
end
