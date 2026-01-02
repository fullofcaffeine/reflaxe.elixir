defmodule Test.Components do
  use Phoenix.Component
  def card(assigns) do
    ~H"""
<div><h2><%= @title %></h2><%= @inner_content %></div>
"""
  end
end
