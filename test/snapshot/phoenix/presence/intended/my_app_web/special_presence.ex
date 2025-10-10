defmodule MyAppWeb.SpecialPresence do
  alias MyApp.Repo, as: Repo
  def track_special(socket, key, meta) do
    Presence.track(self(), socket, key, meta)
  end
  def track_with_string_op(socket, user_id, meta) do
    user_key = if String.length(user_id) > 0, do: user_id, else: "anonymous"
    Presence.track(self(), socket, user_key, meta)
  end
end