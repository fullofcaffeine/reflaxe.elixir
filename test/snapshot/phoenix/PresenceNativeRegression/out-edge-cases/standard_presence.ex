defmodule StandardPresence do
  use Phoenix.Presence, otp_app: :standard_presence
  def track_item(socket, item_id, metadata) do
    track(self(), socket, item_id, metadata)
  end
end