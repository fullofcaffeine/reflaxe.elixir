defmodule MyAppWeb.PresenceLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def mount(_, session, socket) do
    user_id = Map.get(session, :user_id)
    socket = MyApp.Presence.track(self(), socket, user_id, %{:joined_at => DateTime.to_iso8601(DateTime.utc_now())})
    %{:ok => socket}
    {:ok, socket}
  end
  def handle_event(event, params, socket) do
    (case event do
      "user_stopped_typing" -> %{:noreply => MyApp.Presence.update(self(), socket, Map.get(params, :user_id), %{:typing => false})}
      "user_typing" -> %{:noreply => MyApp.Presence.update(self(), socket, Map.get(params, :user_id), %{:typing => true})}
      _ -> %{:noreply => socket}
    end)
  end
end
