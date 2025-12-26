defmodule RegularPresence do
  use Phoenix.Presence, otp_app: :regular_presence, pubsub_server: RegularPresence.PubSub
  def track_user(socket, user_id, meta) do
    Presence.track(self(), socket, user_id, meta)
  end
end
