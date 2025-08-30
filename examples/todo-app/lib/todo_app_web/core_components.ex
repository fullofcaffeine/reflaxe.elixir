defmodule TodoAppWeb.CoreComponents do
  def modal() do
    fn assigns -> ~H"""
<div id={@id} class="modal" phx-show={@show}>
            <%= @inner_content %>
        </div>
""" end
  end
  def button() do
    fn assigns -> ~H"""
<button type={@type || "button"} class={@className} disabled={@disabled}>
            <%= @inner_content %>
        </button>
""" end
  end
  def input() do
    fn assigns -> ~H"""
<div class="form-group">
            <label for={@field.id}><%= @label %></label>
            <input 
                type={@type || "text"} 
                id={@field.id}
                name={@field.name}
                value={@field.value}
                placeholder={@placeholder}
                class="form-control"
                required={@required}
            />
            <%= if @field.errors && length(@field.errors) > 0 do %>
                <span class="error"><%= Enum.join(@field.errors, ", ") %></span>
            <% end %>
        </div>
""" end
  end
  def error() do
    fn assigns -> ~H"""
<%= if @field && @field.errors && length(@field.errors) > 0 do %>
            <div class="error-message">
                <%= Enum.join(@field.errors, ", ") %>
            </div>
        <% end %>
""" end
  end
  def simple_form() do
    fn assigns -> ~H"""
<.form :let={f} for={@formFor} action={@action} method={@method || "post"}>
            <%= @inner_content %>
        </.form>
""" end
  end
  def header() do
    fn assigns -> ~H"""
<header class="header">
            <h1><%= @title %></h1>
            <%= if @actions do %>
                <div class="actions">
                    <%= @actions %>
                </div>
            <% end %>
        </header>
""" end
  end
  def table() do
    fn assigns -> ~H"""
<table class="table">
            <thead>
                <tr>
                    <%= for col <- @columns do %>
                        <th><%= col.label %></th>
                    <% end %>
                </tr>
            </thead>
            <tbody>
                <%= for row <- @rows do %>
                    <tr>
                        <%= for col <- @columns do %>
                            <td><%= Map.get(row, col.field) %></td>
                        <% end %>
                    </tr>
                <% end %>
            </tbody>
        </table>
""" end
  end
  def list() do
    fn assigns -> ~H"""
<ul class="list">
            <%= for item <- @items do %>
                <li><%= item %></li>
            <% end %>
        </ul>
""" end
  end
  def back() do
    fn assigns -> ~H"""
<div class="back-link">
            <.link navigate={@navigate}>
                ← Back
            </.link>
        </div>
""" end
  end
  def icon() do
    fn assigns -> ~H"""
<%= if @className do %>
            <span class={"icon icon-" <> @name <> " " <> @className}></span>
        <% else %>
            <span class={"icon icon-" <> @name}></span>
        <% end %>
""" end
  end
  def label() do
    fn assigns -> ~H"""
<%= if @htmlFor do %>
            <label for={@htmlFor} class={@className}><%= @inner_content %></label>
        <% else %>
            <label class={@className}><%= @inner_content %></label>
        <% end %>
""" end
  end
end