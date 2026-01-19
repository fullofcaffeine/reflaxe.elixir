defmodule AppWeb.Presence do
  use Phoenix.Presence, otp_app: :app, pubsub_server: App.PubSub
  def exercise() do
    presences = Phoenix.Presence.list("users")
    _g = 0
    g_value = Reflect.fields(presences)
    _ = Enum.each(g_value, fn _ -> nil end)
  end
end
