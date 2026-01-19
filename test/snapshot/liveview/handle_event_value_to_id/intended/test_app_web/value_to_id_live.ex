defmodule TestAppWeb.ValueToIdLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {TestAppWeb.Layouts, :app}
  def mount(_, _, socket) do
    {:ok, socket}
  end
  defp toggle_todo(_, _) do
    
  end
  def handle_event(event, params, socket) do
    if (event == "toggle_todo") do
      toggle_todo(params, socket)
    else
      
    end
    {:noreply, socket}
  end
end
