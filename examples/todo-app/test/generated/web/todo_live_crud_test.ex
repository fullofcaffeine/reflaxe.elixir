defmodule TodoLiveCrudTest do
  use Phoenix.Component
  use ExUnit.Case
  import Phoenix.ConnTest
  alias Phoenix.ConnTest, as: ConnTest
  import Phoenix.LiveViewTest
  alias Phoenix.LiveViewTest, as: LiveViewTest
  @endpoint TodoAppWeb.Endpoint
  test "mount todos" do
    conn = ConnTest.build_conn()
    lv = case Phoenix.LiveViewTest.live(conn, "/todos") do {:ok, v, _html} -> v end
    assert lv != nil
    html = Phoenix.LiveViewTest.render(lv)
    assert html != nil
  end
end
