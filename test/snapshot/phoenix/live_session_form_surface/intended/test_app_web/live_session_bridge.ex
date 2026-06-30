defmodule TestAppWeb.LiveSessionBridge do
  def live_session(conn) do

              Enum.reduce(["user_id", "organization_id"], %{}, fn key, acc ->
                case Plug.Conn.get_session(conn, key) do
                  nil -> acc
                  value -> Map.put(acc, key, value)
                end
              end)

  end
end
