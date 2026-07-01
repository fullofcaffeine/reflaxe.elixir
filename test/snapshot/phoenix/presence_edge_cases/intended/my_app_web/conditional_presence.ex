defmodule MyAppWeb.ConditionalPresence do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def track_conditionally(socket, user_id, is_admin, meta) do
    if (is_admin) do
      MyApp.Presence.track(self(), socket, user_id, %{role: "admin", meta: meta})
    else
      MyApp.Presence.track(self(), socket, user_id, %{role: "user", meta: meta})
    end
  end
  def track_in_switch(socket, user_id, user_type, _meta) do
    (case user_type do
      "admin" ->
        MyApp.Presence.track(self(), socket, user_id, %{role: "admin", permissions: "all"})
      "moderator" ->
        MyApp.Presence.track(self(), socket, user_id, %{role: "mod", permissions: "some"})
      _ ->
        MyApp.Presence.track(self(), socket, user_id, %{role: "user", permissions: "basic"})
    end)
  end
end
