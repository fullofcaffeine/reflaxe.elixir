defmodule MyAppWeb.OptionalLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def render(assigns) do
    ~H"""
<section>
			<button phx-click={"search"}>Search</button>
			<form phx-submit={"save_profile"}>
				<input type="text" name="profile[name]" value={@summary} />
			</form>
		</section>
"""
  end
  def decode_search(payload) do
    MyApp.OptionalEvents.decode("search", payload)
  end
  defp handle_search(query, socket) do
    summary = if (Kernel.is_nil(query)), do: "all", else: query
    {:noreply, Phoenix.Component.assign(socket, :summary, summary)}
  end
  defp handle_save_profile(payload, socket) do
    summary = if (Kernel.is_nil(payload.bio)) do
      payload.name
    else
      "#{payload.name}:#{payload.bio}"
    end
    {:noreply, Phoenix.Component.assign(socket, :summary, summary)}
  end
  defp dispatch_optional_event(event_name, payload, socket) do
    cond do
      event_name == "save_profile" ->
        event_payload_root = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
          Map.get(payload, "profile")
        else
          nil
        end
        event_payload = if (not Kernel.is_nil(event_payload_root) and Kernel.is_map(event_payload_root)), do: event_payload_root, else: %{}
        bio_raw = Map.get(event_payload, "bio")
        bio = if (Kernel.is_binary(bio_raw)), do: bio_raw, else: nil
        name_raw = Map.get(event_payload, "name")
        name = if (Kernel.is_binary(name_raw)), do: name_raw, else: nil
        if (Kernel.is_nil(name)), do: {:noreply, socket}, else: handle_save_profile(%{:bio => bio, :name => name}, socket)
      event_name == "search" ->
        event_payload = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)), do: payload, else: %{}
        query_raw = Map.get(event_payload, "query")
        query = if (Kernel.is_binary(query_raw)), do: query_raw, else: nil
        handler_result = handle_search(query, socket)
        handler_result
      true -> nil
    end
  end
  def handle_event(event, params, socket) do
    handled = dispatch_optional_event(event, params, socket)
    if (not Kernel.is_nil(handled)), do: handled, else: {:noreply, socket}
  end
end
