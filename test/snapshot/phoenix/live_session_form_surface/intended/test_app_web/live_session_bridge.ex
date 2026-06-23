defmodule TestAppWeb.LiveSessionBridge do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {TestAppWeb.Layouts, :app}
  def live_session(conn) do

              Enum.reduce(["user_id", "organization_id"], %{}, fn key, acc ->
                case Plug.Conn.get_session(conn, key) do
                  nil -> acc
                  value -> Map.put(acc, key, value)
                end
              end)

  end
end
