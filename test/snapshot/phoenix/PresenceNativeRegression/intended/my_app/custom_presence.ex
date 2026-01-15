defmodule MyApp.CustomPresence do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def track3_args(socket, key, meta) do
    Presence.track(self(), socket, key, meta)
  end
  def update_key(socket, key, meta) do
    Presence.update(self(), socket, key, meta)
  end
  def untrack_key(socket, key) do
    Presence.untrack(self(), socket, key)
  end
end
