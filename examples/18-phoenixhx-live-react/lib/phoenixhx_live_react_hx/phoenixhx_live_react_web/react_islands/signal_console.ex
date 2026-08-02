defmodule PhoenixhxLiveReactWeb.ReactIslands.SignalConsole do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
    <div class="react-island-host">
          <LiveReact.react id={@id} name="SignalConsole" title={@title} pulseCount={@pulse_count} ssr={false}></LiveReact.react>
        </div>
    """
  end
end
