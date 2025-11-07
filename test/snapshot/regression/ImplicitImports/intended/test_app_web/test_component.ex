defmodule TestAppWeb.TestComponent do
  use Phoenix.Component
  def template(assigns) do
    ~H"""
<div class={@className}>
    <h1><%= @title %></h1>
    <p><%= @content %></p>
</div>
"""
  end
  def button(assigns) do
    ~H"""
<button type={@type || "button"} disabled={@disabled}>
    <%= @label %>
</button>
"""
  end
end
