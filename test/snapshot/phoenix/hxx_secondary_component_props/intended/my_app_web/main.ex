defmodule MyAppWeb.Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
    <div><MyAppWeb.Components.card title="Hello" label={true} js={@js} details={%{count: 2}}></MyAppWeb.Components.card></div>
    """
  end
  def main() do

  end
end
