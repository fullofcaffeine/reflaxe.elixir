defmodule StandardPresence do
  use Phoenix.Presence, otp_app: :standard_presence, pubsub_server: StandardPresence.PubSub
  def track_item(socket, item_id, metadata) do
    Presence.track(self(), socket, item_id, metadata)
  end
end
