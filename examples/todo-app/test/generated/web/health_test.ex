defmodule HealthTest do
  use ExUnit.Case
  import Phoenix.ConnTest
  alias Phoenix.ConnTest, as: ConnTest
  import Phoenix.LiveViewTest
  alias Phoenix.LiveViewTest, as: LiveViewTest
  @endpoint TodoAppWeb.Endpoint
  test "home page loads" do
    conn = ConnTest.build_conn()
    conn = ConnTest.get(conn, "/")
    assert conn != nil
    status = conn.status
    assert status == 200
  end
end
