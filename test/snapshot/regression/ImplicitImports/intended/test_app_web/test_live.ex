defmodule TestAppWeb.TestLive do
  use TestAppWeb, :live_view
  def mount(params, session, socket) do
    %{:status => "ok", :socket => socket}
  end
  def render(assigns) do
    "\n            <div>\n                <.header title=\"Test Page\" />\n                \n                <.button type=\"submit\">\n                    Submit Form\n                </.button>\n                \n                <.input field={@form[\"name\"]} label=\"Name\" />\n                \n                <.modal id=\"test-modal\" show={@show_modal}>\n                    Modal Content Here\n                </.modal>\n            </div>\n        "
  end
  def handle_event(event, params, socket) do
    %{:status => "noreply", :socket => socket}
  end
end