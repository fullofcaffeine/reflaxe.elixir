defmodule MyAppWeb.MixedUsage do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def local_and_remote(socket, user_id) do
    MyAppWeb.MixedUsage.track(self(), "local", user_id, %{local: true})
    MyAppWeb.ConditionalPresence.track_conditionally(socket, user_id, false)
  end
  def track_internal(topic, key, meta) do
    MyAppWeb.MixedUsage.track(self(), topic, key, meta)
  end
  def update_internal(topic, key, meta) do
    MyAppWeb.MixedUsage.update(self(), topic, key, meta)
  end
  def untrack_internal(topic, key) do
    MyAppWeb.MixedUsage.untrack(self(), topic, key)
  end
  def track_with_socket(socket, topic, key, meta) do
    MyAppWeb.MixedUsage.track(self(), topic, key, meta)
    socket
  end
  def update_with_socket(socket, topic, key, meta) do
    MyAppWeb.MixedUsage.update(self(), topic, key, meta)
    socket
  end
  def untrack_with_socket(socket, topic, key) do
    MyAppWeb.MixedUsage.untrack(self(), topic, key)
    socket
  end
end
