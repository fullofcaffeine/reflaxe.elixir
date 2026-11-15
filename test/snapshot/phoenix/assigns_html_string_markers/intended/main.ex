defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
    <p>Hello <%= @name %></p>
    """
  end
  def help(assigns) do
    ~H"""
    <p>Write <%= 1 + 1 %> to <%= @name %></p>
    """
  end
  def help_plain(assigns) do
    ~H"""
    <p>No marker</p>
    """
  end
  def via_var(assigns) do
    html = ~H"""
    <i><%= @name %></i>
    """
    html
  end
  def nested(assigns) do
    inner = if (assigns.on), do: "<b>on</b>", else: "<i>off</i>"
    ~H"""
    <div><%= Phoenix.HTML.raw(inner) %></div>
    """
  end
  def mixed(assigns) do
    title = shout("\#{raw}")
    ~H"""
    <h2><%= title %></h2>
    """
  end
  def label(assigns) do
    "no tags \#{assigns.name}"
  end
  def plain(_name) do
    "<p>\#{name}</p>"
  end
  def shout(text) do
    String.upcase(text)
  end
  def main() do

  end
end
