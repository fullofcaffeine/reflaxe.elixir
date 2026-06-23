defmodule PhoenixHxTodoWeb.LiveSession do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {PhoenixHxTodoWeb.Layouts, :app}
  def live_session(conn) do
    user_id = Plug.Conn.get_session(conn, String.to_atom("user_id"))
    session_map = %{}
    if (Reflaxe.Elixir.HaxeFloat.neq(user_id, nil)) do
      Map.put(session_map, "user_id", user_id)
    else
      session_map
    end
  end
end
