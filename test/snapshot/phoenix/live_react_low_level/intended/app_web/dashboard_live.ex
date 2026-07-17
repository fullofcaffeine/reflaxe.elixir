defmodule AppWeb.DashboardLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {AppWeb.Layouts, :app}
  def render(assigns) do
    ~H"""
    <main>
          <AppWeb.ReactComponents.status_card id={@island_id} title={@title}></AppWeb.ReactComponents.status_card>
        </main>
    """
  end
  def main() do

  end
end
