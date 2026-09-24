defmodule MyAppWeb.Components do
  use Phoenix.Component
  def card(assigns) do
    ~H"""
    <p><%= @title %></p>
    """
  end
end
