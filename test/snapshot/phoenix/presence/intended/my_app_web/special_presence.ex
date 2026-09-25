defmodule MyAppWeb.SpecialPresence do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def track_special(socket, key, meta) do
    topic = "special"
    MyAppWeb.SpecialPresence.track(self(), topic, key, meta)
    socket
  end
  def track_with_string_op(socket, user_id) do
    key = if (String.length(user_id) > 0), do: user_id, else: "anonymous"
    track_special(socket, key, %{status: "special"})
  end
  def track_internal(topic, key, meta) do
    MyAppWeb.SpecialPresence.track(self(), topic, key, meta)
  end
  def update_internal(topic, key, meta) do
    MyAppWeb.SpecialPresence.update(self(), topic, key, meta)
  end
  def untrack_internal(topic, key) do
    MyAppWeb.SpecialPresence.untrack(self(), topic, key)
  end
  def track_with_socket(socket, topic, key, meta) do
    MyAppWeb.SpecialPresence.track(self(), topic, key, meta)
    socket
  end
  def update_with_socket(socket, topic, key, meta) do
    MyAppWeb.SpecialPresence.update(self(), topic, key, meta)
    socket
  end
  def untrack_with_socket(socket, topic, key) do
    MyAppWeb.SpecialPresence.untrack(self(), topic, key)
    socket
  end
end
