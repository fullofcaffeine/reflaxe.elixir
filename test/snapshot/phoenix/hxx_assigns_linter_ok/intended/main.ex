defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<div>
      <p>User: <%= @user.name %></p>
      <p class={if @active, do: "on", else: "off"}>Status</p>
      <p><%= if @sort_by == "created_at" do %>Newest<% else %>Other<% end %></p>
      <span><%= @count %></span>
    </div>
"""
  end
  def main() do
    
  end
end
