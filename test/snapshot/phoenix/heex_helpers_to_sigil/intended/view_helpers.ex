defmodule ViewHelpers do
  use Phoenix.Component
  def panel(assigns) do
    ~H"""
<div class="panel"><h1>Static</h1></div>
"""
  end
end
