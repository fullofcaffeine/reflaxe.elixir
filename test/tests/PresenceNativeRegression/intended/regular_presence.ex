defmodule RegularPresence do
  use Phoenix.Presence, otp_app: :regular_presence
  def track_user(socket, user_id, meta) do
    track(self(), socket, user_id, meta)
  end
end