defmodule MyAppWeb.ComplexPresence do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def track_with_computation(socket, user) do
    MyApp.Presence.track(self(), socket, "#{user.id}_#{Kernel.to_string(DateTime.to_unix(DateTime.utc_now(), :millisecond))}", (fn ->
      v = DateTime.to_iso8601(DateTime.utc_now()) / 1000
      %{:name => user.first_name <> " " <> user.last_name, :timestamp => floor(v), :computed => (if (Map.get(user, :score) > 100), do: "expert", else: "novice")}
    end).())
  end
  def track_nested(socket, users) do
    Enum.map(users, fn user -> MyApp.Presence.track(self(), socket, user.id, %{:status => "online"}) end)
  end
end
