defmodule MyApp.CustomPresence do
  use Phoenix.Presence, otp_app: :my_app
  def track3_args(socket, key, meta) do
    track(self(), socket, key, meta)
  end
  def update_key(socket, key, meta) do
    update(self(), socket, key, meta)
  end
  def untrack_key(socket, key) do
    untrack(self(), socket, key)
  end
end