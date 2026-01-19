defmodule MyAppWeb.MixedUsage do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def local_and_remote(socket, user_id) do
    MyApp.Presence.track(self(), socket, user_id, %{:local => true})
  end
end
