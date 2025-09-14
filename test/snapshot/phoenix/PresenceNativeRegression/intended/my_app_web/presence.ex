defmodule MyAppWeb.Presence do
  use Phoenix.Presence, otp_app: :my_app
  def track_user(socket, user_id, meta) do
    track(self(), socket, user_id, meta)
  end
  def update_user(socket, user_id, meta) do
    update(self(), socket, user_id, meta)
  end
  def untrack_user(socket, user_id) do
    untrack(self(), socket, user_id)
  end
end