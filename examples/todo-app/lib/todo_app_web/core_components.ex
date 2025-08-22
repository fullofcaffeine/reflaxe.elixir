defmodule TodoAppWeb.CoreComponents do
  @moduledoc """
  Core UI components for Phoenix applications.
  
  Generated from Haxe CoreComponents with type safety and consistent styling.
  """
  use Phoenix.Component

  def modal(assigns) do
    ~H"""
  <div id={@id} class="modal" phx-show={@show}>
  <%= @inner_content %>
  </div>
  """
  end

  def button(assigns) do
    ~H"""
  <button type={@type || "button"} class={@className} disabled={@disabled}>
  <%= @inner_content %>
  </button>
  """
  end

  def input(assigns) do
    ~H"""
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
  """
  end

  def error(assigns) do
    ~H"""
  <%= if @field && @field.errors && length(@field.errors) > 0 do %>
  <div class="error-message">
  <%= Enum.join(@field.errors, ", ") %>
  </div>
  <% end %>
  """
  end

  def simple_form(assigns) do
    ~H"""
  <.form :let={f} for={@formFor} action={@action} method={@method || "post"}>
  <%= @inner_content %>
  </.form>
  """
  end

  def header(assigns) do
    ~H"""
  <header class="header">
  <h1><%= @title %></h1>
  <%= if @actions do %>
  <div class="actions">
  <%= @actions %>
  </div>
  <% end %>
  </header>
  """
  end

  def table(assigns) do
    ~H"""
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
  """
  end

  def list(assigns) do
    ~H"""
  <ul class="list">
  <%= for item <- @items do %>
  <li><%= item %></li>
  <% end %>
  </ul>
  """
  end

  def back(assigns) do
    ~H"""
  <div class="back-link">
  <.link navigate={@navigate}>
  ← Back
  </.link>
  </div>
  """
  end

  def icon(assigns) do
    ~H"""
  <%= if @className do %>
  <span class={"icon icon-" <> @name <> " " <> @className}></span>
  <% else %>
  <span class={"icon icon-" <> @name}></span>
  <% end %>
  """
  end

  def label(assigns) do
    ~H"""
  <%= if @htmlFor do %>
  <label for={@htmlFor} class={@className}><%= @inner_content %></label>
  <% else %>
  <label class={@className}><%= @inner_content %></label>
  <% end %>
  """
  end

end
