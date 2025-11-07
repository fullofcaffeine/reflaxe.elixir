defmodule TestAppWeb.TestLive do
  use Phoenix.Component
  use TestAppWeb, :live_view
  require Ecto.Query
  def mount(_params, session, socket) do
    %{:status => "ok", :socket => socket}
  end
  def render(assigns) do
    ~H"""
<div>
    <.header title="Test Page" />
    
    <.button type="submit">
        Submit Form
    </.button>
    
    <.input field={@form["name"]} label="Name" />
    
    <.modal id="test-modal" show={@show_modal}>
        Modal Content Here
    </.modal>
</div>
"""
  end
  def handle_event(event, params, socket) do
    %{:status => "noreply", :socket => socket}
  end
end
