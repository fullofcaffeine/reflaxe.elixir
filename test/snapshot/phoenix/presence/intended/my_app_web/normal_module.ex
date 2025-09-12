defmodule MyAppWeb.NormalModule do
  def track_from_outside(socket, user_id, meta) do
    Phoenix.Presence.track(socket, user_id, meta)
  end
  def update_from_outside(socket, user_id, meta) do
    Phoenix.Presence.update(socket, user_id, meta)
  end
  def list_from_outside(topic) do
    Phoenix.Presence.list(topic)
  end
end