defmodule PhoenixChatWeb.Presence do
  use Phoenix.Presence, otp_app: :phoenix_chat, pubsub_server: PhoenixChat.PubSub
  def track_internal(topic, key, meta) do
    PhoenixChatWeb.Presence.track(self(), topic, key, meta)
  end
  def update_internal(topic, key, meta) do
    PhoenixChatWeb.Presence.update(self(), topic, key, meta)
  end
  def untrack_internal(topic, key) do
    PhoenixChatWeb.Presence.untrack(self(), topic, key)
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
