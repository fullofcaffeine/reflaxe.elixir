defmodule TestAppWeb.ValueDecodeLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {TestAppWeb.Layouts, :app}
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
  defp perform_search(_payload, _socket) do
    
  end
  def handle_event(event, params, socket) do
    if (event == "search_todos") do
      perform_search(params, socket)
    else
      
    end
    {:noreply, socket}
  end
end
