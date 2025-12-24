defmodule TestAppWeb.TestLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {TestAppWeb.Layouts, :app}
  def mount(_params, session, socket) do
    {:ok, socket}
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
  def handle_event(event, _params, socket) do
    {:noreply, socket}
  end
end
