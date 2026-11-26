defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    if (assigns.on) do
      Views.compact(assigns)
    else
      Views.full(assigns)
    end
  end
  defp badge_class(assigns, flag) do
    label = if (flag), do: "on", else: "off"
    String.upcase(label)
  end
  def badge(assigns, flag) do
    badge_class(assigns, flag)
  end
  def card(assigns) do
    ~H"""
    <div>hi</div>
    """
  end
  def main() do

  end
end
