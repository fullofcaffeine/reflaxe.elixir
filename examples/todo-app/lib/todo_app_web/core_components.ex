defmodule TodoAppWeb.CoreComponents do
  def modal(_assigns) do
    "<div id={@id} class=\"modal\" phx-show={@show}>\n            <%= @inner_content %>\n        </div>"
  end
  def button(_assigns) do
    "<button type={@type || \"button\"} class={@className} disabled={@disabled}>\n            <%= @inner_content %>\n        </button>"
  end
  def input(_assigns) do
    "<div class=\"form-group\">\n            <label for={@field.id}><%= @label %></label>\n            <input \n                type={@type || \"text\"} \n                id={@field.id}\n                name={@field.name}\n                value={@field.value}\n                placeholder={@placeholder}\n                class=\"form-control\"\n                required={@required}\n            />\n            <%= if @field.errors && length(@field.errors) > 0 do %>\n                <span class=\"error\"><%= Enum.join(@field.errors, \", \") %></span>\n            <% end %>\n        </div>"
  end
  def error(_assigns) do
    "<%= if @field && @field.errors && length(@field.errors) > 0 do %>\n            <div class=\"error-message\">\n                <%= Enum.join(@field.errors, \", \") %>\n            </div>\n        <% end %>"
  end
  def simple_form(_assigns) do
    "<.form :let={f} for={@formFor} action={@action} method={@method || \"post\"}>\n            <%= @inner_content %>\n        </.form>"
  end
  def header(_assigns) do
    "<header class=\"header\">\n            <h1><%= @title %></h1>\n            <%= if @actions do %>\n                <div class=\"actions\">\n                    <%= @actions %>\n                </div>\n            <% end %>\n        </header>"
  end
  def table(_assigns) do
    "<table class=\"table\">\n            <thead>\n                <tr>\n                    <%= for col <- @columns do %>\n                        <th><%= col.label %></th>\n                    <% end %>\n                </tr>\n            </thead>\n            <tbody>\n                <%= for row <- @rows do %>\n                    <tr>\n                        <%= for col <- @columns do %>\n                            <td><%= Map.get(row, col.field) %></td>\n                        <% end %>\n                    </tr>\n                <% end %>\n            </tbody>\n        </table>"
  end
  def list(_assigns) do
    "<ul class=\"list\">\n            <%= for item <- @items do %>\n                <li><%= item %></li>\n            <% end %>\n        </ul>"
  end
  def back(_assigns) do
    "<div class=\"back-link\">\n            <.link navigate={@navigate}>\n                ← Back\n            </.link>\n        </div>"
  end
  def icon(_assigns) do
    "<%= if @className do %>\n            <span class={\"icon icon-\" <> @name <> \" \" <> @className}></span>\n        <% else %>\n            <span class={\"icon icon-\" <> @name}></span>\n        <% end %>"
  end
  def label(_assigns) do
    "<%= if @htmlFor do %>\n            <label for={@htmlFor} class={@className}><%= @inner_content %></label>\n        <% else %>\n            <label class={@className}><%= @inner_content %></label>\n        <% end %>"
  end
end