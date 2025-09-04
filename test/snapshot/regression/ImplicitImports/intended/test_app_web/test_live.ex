defmodule TestAppWeb.TestLive do
  use TestAppWeb, :live_view
  import TestAppWeb.CoreComponents, except: [label: 1]
  def mount(params, session, socket) do
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