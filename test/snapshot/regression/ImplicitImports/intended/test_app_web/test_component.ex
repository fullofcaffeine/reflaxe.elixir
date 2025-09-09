defmodule TestAppWeb.TestComponent do
  def render(_assigns) do
    "\n            <div class={@className}>\n                <h1><%= @title %></h1>\n                <p><%= @content %></p>\n            </div>\n        "
  end
  def button(_assigns) do
    "\n            <button type={@type || \"button\"} disabled={@disabled}>\n                <%= @label %>\n            </button>\n        "
  end
end