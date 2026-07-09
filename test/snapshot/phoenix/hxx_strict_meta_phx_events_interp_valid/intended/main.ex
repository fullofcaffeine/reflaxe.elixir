defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
    <button phx-click={"save"}>Save</button>
    """
  end
  def main() do

  end
end
