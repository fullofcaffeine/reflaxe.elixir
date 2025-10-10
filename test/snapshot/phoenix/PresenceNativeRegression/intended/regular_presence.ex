defmodule RegularPresence do
  def track_user(socket, user_id, meta) do
    Presence.track(self(), socket, user_id, meta)
  end
end