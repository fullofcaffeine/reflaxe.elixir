defmodule MyAppWeb.NormalModule do
  def track_from_outside(socket, user_id, meta) do
    Presence.track(self(), socket, user_id, meta)
  end
  def update_from_outside(socket, user_id, meta) do
    Presence.update(self(), socket, user_id, meta)
  end
  def list_from_outside(topic) do
    Presence.list(topic)
  end
end