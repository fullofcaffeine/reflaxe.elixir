defmodule ProfileLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {ProfileLive.Layouts, :app}
  defp handle_clipboard_copied(message, socket) do
    {:noreply, Phoenix.Component.assign(socket, :flash_message, message)}
  end
  defp dispatch_profile_hook_event(event_name, payload, socket) do
    if (event_name == "clipboard_copied") do
      message_raw = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
        Map.get(payload, "message")
      else
        nil
      end
      message = if (Kernel.is_binary(message_raw)), do: message_raw, else: nil
      if (Kernel.is_nil(message)), do: {:noreply, socket}, else: handle_clipboard_copied(message, socket)
    else
      nil
    end
  end
  def handle_event(event, params, socket) do
    hook_result = dispatch_profile_hook_event(event, params, socket)
    if (not Kernel.is_nil(hook_result)) do
      hook_result
    else
      if (event == "clipboard_copied"), do: {:noreply, Phoenix.Component.assign(socket, :flash_message, "fallback should not handle malformed protocol payloads")}, else: {:noreply, socket}
    end
  end
end
