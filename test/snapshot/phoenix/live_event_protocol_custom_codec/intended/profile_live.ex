defmodule ProfileLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {ProfileLive.Layouts, :app}
  def encode_selected(todo_id, source) do
    payload = %{:todo_id => todo_id, :source => source}
    _ = TodoHookEvents.encode({:todo_selected, payload})
  end
  def decode_selected(payload) do
    TodoHookEvents.decode("todo_selected", payload)
  end
  defp handle_todo_selected(payload, socket) do
    {:noreply, Phoenix.Component.assign(socket, :selected_todo_id, payload.todo_id)}
  end
  defp handle_ping(socket) do
    {:noreply, socket}
  end
  defp dispatch_todo_hook_event(event_name, payload, socket) do
    cond do
      event_name == "ping" -> handle_ping(socket)
      event_name == "todo_selected" ->
        source = Phoenix.Channels.WirePayload.get_string(payload, "source")
        raw = Phoenix.Channels.WirePayload.get_payload(payload, "todo_id")
        todo_id = if (not Kernel.is_nil(raw)), do: TodoIdCodec.codec().decode.(raw), else: nil
        if (Kernel.is_nil(source) or Kernel.is_nil(todo_id)), do: nil, else: handle_todo_selected(%{:source => source, :todo_id => todo_id}, socket)
      :true -> nil
    end
  end
  def handle_event(event, params, socket) do
    hook_result = dispatch_todo_hook_event(event, params, socket)
    if (not Kernel.is_nil(hook_result)), do: hook_result, else: {:noreply, socket}
  end
end
