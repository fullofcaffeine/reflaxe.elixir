defmodule ProfileLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {ProfileLive.Layouts, :app}
  def encode_selected(resource_id, source) do
    payload = %{:resource_id => resource_id, :source => source}
    _ = ResourceHookEvents.encode({:resource_selected, payload})
  end
  def decode_selected(payload) do
    ResourceHookEvents.decode("resource_selected", payload)
  end
  defp handle_resource_selected(payload, socket) do
    {:noreply, Phoenix.Component.assign(socket, :selected_resource_id, payload.resource_id)}
  end
  defp handle_ping(socket) do
    {:noreply, socket}
  end
  defp dispatch_resource_hook_event(event_name, payload, socket) do
    cond do
      event_name == "ping" -> handle_ping(socket)
      event_name == "resource_selected" ->
        raw = Phoenix.Channels.WirePayload.get_payload(payload, "resource_id")
        resource_id = if (not Kernel.is_nil(raw)), do: ResourceIdCodec.codec().decode.(raw), else: nil
        source = Phoenix.Channels.WirePayload.get_string(payload, "source")
        if (Kernel.is_nil(resource_id) or Kernel.is_nil(source)), do: nil, else: handle_resource_selected(%{:resource_id => resource_id, :source => source}, socket)
      :true -> nil
    end
  end
  def handle_event(event, params, socket) do
    hook_result = dispatch_resource_hook_event(event, params, socket)
    if (not Kernel.is_nil(hook_result)), do: hook_result, else: {:noreply, socket}
  end
end
