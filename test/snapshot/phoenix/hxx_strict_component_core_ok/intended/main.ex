defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
    <.link navigate="/todos">Todos</.link>
    """
  end
  def main() do

  end
end
