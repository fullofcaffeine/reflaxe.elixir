defmodule MyAppWeb.Presence do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def track_internal(topic, key, meta) do
    MyAppWeb.Presence.track(self(), topic, key, meta)
  end
  def update_internal(topic, key, meta) do
    MyAppWeb.Presence.update(self(), topic, key, meta)
  end
  def untrack_internal(topic, key) do
    MyAppWeb.Presence.untrack(self(), topic, key)
  end
  def track_with_socket(socket, _topic, _key, _meta) do
    socket
  end
  def update_with_socket(socket, _topic, _key, _meta) do
    socket
  end
  def untrack_with_socket(socket, _topic, _key) do
    socket
  end
end
