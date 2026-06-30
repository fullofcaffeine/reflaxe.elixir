defmodule MyAppWeb.ProfileLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def encode_copied(message, copied_at) do
    payload = %{:message => message, :copied_at => copied_at}
    _ = MyApp.ProfileHookEvents.encode({:clipboard_copied, payload})
  end
  def decode_copied(payload) do
    MyApp.ProfileHookEvents.decode("clipboard_copied", payload)
  end
  defp handle_clipboard_copied(payload, socket) do
    {:noreply, Phoenix.Component.assign(socket, :flash_message, payload.message)}
  end
  defp handle_ping(socket) do
    {:noreply, socket}
  end
  defp dispatch_profile_hook_event(event_name, payload, socket) do
    cond do
      event_name == "clipboard_copied" ->
        copied_at_raw = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
          Map.get(payload, "copied_at")
        else
          nil
        end
        copied_at = if (Kernel.is_binary(copied_at_raw)), do: copied_at_raw, else: nil
        message_raw = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
          Map.get(payload, "message")
        else
          nil
        end
        message = if (Kernel.is_binary(message_raw)), do: message_raw, else: nil
        if (Kernel.is_nil(copied_at) or Kernel.is_nil(message)), do: {:noreply, socket}, else: handle_clipboard_copied(%{:copied_at => copied_at, :message => message}, socket)
      event_name == "ping" -> handle_ping(socket)
      true -> nil
    end
  end
  def handle_event(event, params, socket) do
    hook_result = dispatch_profile_hook_event(event, params, socket)
    if (not Kernel.is_nil(hook_result)), do: hook_result, else: {:noreply, socket}
  end
end
