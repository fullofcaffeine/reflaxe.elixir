defmodule TestAppWeb.TestLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {TestAppWeb.Layouts, :app}
  require Ecto.Query
  def mount(_params, _session, socket) do
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
  def handle_event(_event, _params, socket) do
    %{:status => "noreply", :socket => socket}
  end
end
