defmodule MyAppWeb.Presence do
  use Phoenix.Presence, otp_app: :my_app
  def track_user(socket, user_id, meta) do
    MyAppWeb.Presence.track(self(), socket, user_id, meta)
  end
  def update_user(socket, user_id, meta) do
    MyAppWeb.Presence.update(self(), socket, user_id, meta)
  end
  def untrack_user(socket, user_id) do
    MyAppWeb.Presence.untrack(self(), socket, user_id)
  end
end
