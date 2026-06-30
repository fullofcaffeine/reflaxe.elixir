defmodule MyAppWeb.TodoLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def render(assigns) do
    ~H"""
<button phx-click={"toggle_todo"} phx-value-id="1"><%= @last_id %></button>
"""
  end
  def toggle_event_name() do
    "toggle_todo"
  end
  def decode_toggle(payload) do
    MyApp.TodoEvents.decode("toggle_todo", payload)
  end
  defp handle_toggle_todo(id, socket) do
    {:noreply, Phoenix.Component.assign(socket, :last_id, Reflaxe.Elixir.HaxeFloat.to_string(id))}
  end
  defp handle_clipboard_copied(message, socket) do
    {:noreply, Phoenix.Component.assign(socket, :last_id, message)}
  end
  defp dispatch_todo_event(event_name, payload, socket) do
    cond do
      event_name == "clipboard_copied" ->
        event_payload = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)), do: payload, else: %{}
        message_raw = Map.get(event_payload, "message")
        message = if (Kernel.is_binary(message_raw)), do: message_raw, else: nil
        if (Kernel.is_nil(message)), do: {:noreply, socket}, else: handle_clipboard_copied(message, socket)
      event_name == "toggle_todo" ->
        event_payload = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)), do: payload, else: %{}
        id_raw = Map.get(event_payload, "id")
        id = cond do
          Kernel.is_integer(id_raw) -> id_raw
          Kernel.is_binary(id_raw) ->
            (case Integer.parse(id_raw) do
              {num, _} -> num
              :error -> nil
            end)
          true -> nil
        end
        if (Kernel.is_nil(id)), do: {:noreply, socket}, else: handle_toggle_todo(id, socket)
      true -> nil
    end
  end
  def handle_event(event, params, socket) do
    handled = dispatch_todo_event(event, params, socket)
    if (not Kernel.is_nil(handled)), do: handled, else: {:noreply, socket}
  end
end
