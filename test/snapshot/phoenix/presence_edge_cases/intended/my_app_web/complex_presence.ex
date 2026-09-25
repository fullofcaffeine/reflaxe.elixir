defmodule MyAppWeb.ComplexPresence do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def track_with_computation(socket, user) do
    key = "#{user.id}_key"
    meta = %{name: user.first_name <> " " <> user.last_name, computed: (if (user.score > 100), do: "expert", else: "novice")}
    MyAppWeb.ComplexPresence.track(self(), "computed", key, meta)
    socket
  end
  def track_nested(socket, users) do
    Enum.map(users, fn user ->
      key = user.id
      MyAppWeb.ComplexPresence.track(self(), "nested", key, %{status: "online"})
      socket
    end)
  end
  def track_internal(topic, key, meta) do
    MyAppWeb.ComplexPresence.track(self(), topic, key, meta)
  end
  def update_internal(topic, key, meta) do
    MyAppWeb.ComplexPresence.update(self(), topic, key, meta)
  end
  def untrack_internal(topic, key) do
    MyAppWeb.ComplexPresence.untrack(self(), topic, key)
  end
  def track_with_socket(socket, topic, key, meta) do
    MyAppWeb.ComplexPresence.track(self(), topic, key, meta)
    socket
  end
  def update_with_socket(socket, topic, key, meta) do
    MyAppWeb.ComplexPresence.update(self(), topic, key, meta)
    socket
  end
  def untrack_with_socket(socket, topic, key) do
    MyAppWeb.ComplexPresence.untrack(self(), topic, key)
    socket
  end
end
