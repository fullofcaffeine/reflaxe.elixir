defmodule TodoLiveDueDateTest do
  use Phoenix.Component
  use ExUnit.Case
  import Phoenix.ConnTest
  alias Phoenix.ConnTest, as: ConnTest
  import Phoenix.LiveViewTest
  alias Phoenix.LiveViewTest, as: LiveViewTest
  @endpoint TodoAppWeb.Endpoint
  test "create todo with due date renders" do
    conn = ConnTest.build_conn()
    lv = LiveViewTest.live(conn, "/todos")
    lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']")
    data = %{}
    data.set("title", "DueEarly")
    data.set("due_date", "2025-11-01")
    lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data)
    html = LiveViewTest.render(lv)
    condition = case :binary.match(html, "Due:") do
                {pos, _} -> pos
                :nomatch -> -1
            end != -1
    assert condition
  end
end
