defmodule Main do
  use Phoenix.LiveView, layout: {Main.Layouts, :app}
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end
end
