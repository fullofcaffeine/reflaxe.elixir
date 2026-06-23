defmodule PhoenixHxTodo.AuthFlowTest do
  use ExUnit.Case
  @endpoint PhoenixHxTodoWeb.Endpoint
  require Phoenix.ConnTest
  test "demo login sets session user id" do
    conn = Phoenix.ConnTest.build_conn()
    conn = Phoenix.ConnTest.post(conn, "/auth/demo", %{:name => "Guest Workspace", :email => "guest@example.test"})
    actual = conn.status
    assert actual == 302
    plug_conn = conn
    user_id = Plug.Conn.get_session(plug_conn, String.to_atom("user_id"))
    assert Reflaxe.Elixir.HaxeFloat.neq(user_id, nil)
  end
end
