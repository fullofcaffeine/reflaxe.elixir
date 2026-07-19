defmodule AppWeb.ReactComponents do
  use Phoenix.Component
  def call_stock(assigns) do
    LiveReact.react(assigns)
  end
  def call_reload(assigns) do
    LiveReact.Reload.vite_assets(assigns)
  end
  def status_card(assigns) do
    ~H"""
    <div class="react-island-host">
          <LiveReact.react id={@id} name="StatusCard" title={@title} ssr={false}></LiveReact.react>
        </div>
    """
  end
  def vite_assets(assigns) do
    ~H"""
    <LiveReact.Reload.vite_assets assets={["/js/app.js"]}>
          <script defer phx-track-static type="module" src="/assets/app.js"></script>
        </LiveReact.Reload.vite_assets>
    """
  end
end
