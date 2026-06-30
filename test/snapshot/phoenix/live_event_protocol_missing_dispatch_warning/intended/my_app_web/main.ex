defmodule MyAppWeb.Main do
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end
end
