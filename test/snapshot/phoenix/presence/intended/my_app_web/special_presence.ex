defmodule MyAppWeb.SpecialPresence do
  use Phoenix.Presence, otp_app: :my_app
  def track_special(socket, key, meta) do
    MyAppWeb.Presence.track(self(), socket, key, meta)
  end
  def track_with_string_op(socket, user_id, meta) do
    user_key = if (String.length(user_id) > 0), do: user_id, else: "anonymous"
    _ = MyAppWeb.Presence.track(self(), socket, user_key, meta)
  end
end
