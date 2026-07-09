defmodule PhoenixHxTodo.TodoPersistenceTest do
  use ExUnit.Case
  @endpoint PhoenixHxTodoWeb.Endpoint
  require Phoenix.ConnTest
  import Phoenix.ConnTest
  require Phoenix.LiveViewTest
  test "signed in user can create persisted todo" do
    run_id = Reflaxe.Elixir.HaxeFloat.to_string(((case 1000000000 do
      std_random_max when std_random_max <= 0 -> 0
      std_random_max -> (:rand.uniform(std_random_max) - 1)
    end)))
    title = "Persisted PhoenixHx todo " <> run_id
    conn = Phoenix.ConnTest.build_conn()
    conn = Phoenix.ConnTest.post(conn, "/auth/demo", %{name: "Persisted User", email: "persisted-" <> run_id <> "@example.test"})
    mounted = Phoenix.LiveViewTest.live(conn, "/todos")
    lv = elem(mounted, 1)
    _ = Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_todo']"), %{title: title, notes: "Ecto-backed"})
    html = Phoenix.LiveViewTest.render(lv)
    condition = StringTools.haxe_index_of(html, title, 0) != -1
    assert condition
    condition = StringTools.haxe_index_of(html, "Task added through Ecto", 0) != -1
    assert condition
  end
end
