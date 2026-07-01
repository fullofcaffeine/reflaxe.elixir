defmodule MyAppWeb.IncorrectUsage do
  def try_to_track(socket, user_id) do
    MyApp.Presence.track(self(), socket, user_id, %{status: "attempting"})
  end
end
