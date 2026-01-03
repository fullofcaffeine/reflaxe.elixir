defmodule AppBWeb.CoreComponents do
  use Phoenix.Component
  def card(assigns) do
    ~H"""
<div><h2><%= @headline %></h2><%= @inner_content %></div>
"""
  end
end
