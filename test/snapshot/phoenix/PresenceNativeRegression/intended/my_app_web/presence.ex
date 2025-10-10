defmodule MyAppWeb.Presence do
  alias MyApp.Repo, as: Repo
  def track_user(socket, user_id, meta) do
    Presence.track(self(), socket, user_id, meta)
  end
  def update_user(socket, user_id, meta) do
    Presence.update(self(), socket, user_id, meta)
  end
  def untrack_user(socket, user_id) do
    Presence.untrack(self(), socket, user_id)
  end
end