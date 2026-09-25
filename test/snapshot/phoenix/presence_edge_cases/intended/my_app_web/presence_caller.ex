defmodule MyAppWeb.PresenceCaller do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def register(socket, user_id) do
    MyAppWeb.ConditionalPresence.track_conditionally(socket, user_id, true)
  end
end
