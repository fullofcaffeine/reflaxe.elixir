defmodule AppWeb.ReactComponents do
  use Phoenix.Component
  def call_stock(assigns) do
    LiveReact.react(assigns)
  end
  def status_card(assigns) do
    ~H"""
    <div class="react-island-host">
          <LiveReact.react id={@id} name="StatusCard" title={@title} ssr={false}></LiveReact.react>
        </div>
    """
  end
end
