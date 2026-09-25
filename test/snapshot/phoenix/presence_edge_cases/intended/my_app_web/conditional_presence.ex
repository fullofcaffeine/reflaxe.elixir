defmodule MyAppWeb.ConditionalPresence do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def track_conditionally(socket, user_id, is_admin) do
    if (is_admin) do
      topic = "conditional"
      key = user_id
      MyAppWeb.ConditionalPresence.track(self(), topic, key, %{role: "admin"})
      socket
    else
      topic = "conditional"
      key = user_id
      MyAppWeb.ConditionalPresence.track(self(), topic, key, %{role: "user"})
      socket
    end
  end
  def track_in_switch(socket, user_id, user_type) do
    (case user_type do
      "admin" ->
        MyAppWeb.ConditionalPresence.track(self(), "switch", user_id, %{role: "admin", permissions: "all"})
        socket
      "moderator" ->
        MyAppWeb.ConditionalPresence.track(self(), "switch", user_id, %{role: "mod", permissions: "some"})
        socket
      _ ->
        MyAppWeb.ConditionalPresence.track(self(), "switch", user_id, %{role: "user", permissions: "basic"})
        socket
    end)
  end
  def track_internal(topic, key, meta) do
    MyAppWeb.ConditionalPresence.track(self(), topic, key, meta)
  end
  def update_internal(topic, key, meta) do
    MyAppWeb.ConditionalPresence.update(self(), topic, key, meta)
  end
  def untrack_internal(topic, key) do
    MyAppWeb.ConditionalPresence.untrack(self(), topic, key)
  end
  def track_with_socket(socket, topic, key, meta) do
    MyAppWeb.ConditionalPresence.track(self(), topic, key, meta)
    socket
  end
  def update_with_socket(socket, topic, key, meta) do
    MyAppWeb.ConditionalPresence.update(self(), topic, key, meta)
    socket
  end
  def untrack_with_socket(socket, topic, key) do
    MyAppWeb.ConditionalPresence.untrack(self(), topic, key)
    socket
  end
end
