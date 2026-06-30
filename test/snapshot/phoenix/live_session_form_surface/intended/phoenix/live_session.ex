defmodule LiveSession do
  def empty() do
    %{}
  end
  def put(session, key, value) do
    Map.put(session, key, value)
  end
  def get(session, key) do
    Map.get(session, key)
  end
  def get_with_default(session, key, default_value) do
    Map.get(session, key, default_value)
  end
  def get_int(session, key) do

              case Map.get(session, key) do
                value when is_integer(value) -> value
                _ -> nil
              end

  end
  def from_conn_keys(conn, keys) do

              Enum.reduce(keys, %{}, fn key, acc ->
                case Plug.Conn.get_session(conn, key) do
                  nil -> acc
                  value -> Map.put(acc, key, value)
                end
              end)

  end
end
