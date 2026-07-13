defmodule PhoenixHxTodo.ChatPanelTest do
  use ExUnit.Case
  @endpoint PhoenixHxTodoWeb.Endpoint
  require Phoenix.ConnTest
  import Phoenix.ConnTest
  require Phoenix.LiveViewTest
  test "signed in user can post persisted room note" do
    run_id = Reflaxe.Elixir.HaxeFloat.to_string(((case 1000000000 do
      std_random_max when std_random_max <= 0 -> 0
      std_random_max -> (:rand.uniform(std_random_max) - 1)
    end)))
    body = "Phoenix PubSub room note " <> run_id
    conn = Phoenix.ConnTest.build_conn()
    conn = Phoenix.ConnTest.post(conn, "/auth/demo", %{name: "Chat User", email: "chat-" <> run_id <> "@example.test"})
    mounted = Phoenix.LiveViewTest.live(conn, "/todos")
    lv = elem(mounted, 1)
    Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: body})
    html = Phoenix.LiveViewTest.render(lv)
    condition = StringTools.haxe_index_of(html, body, 0) != -1
    assert condition
    condition = StringTools.haxe_index_of(html, "Room note persisted through Ecto", 0) != -1
    assert condition
  end
  test "ship room shows six most recent notes" do
    run_id = Reflaxe.Elixir.HaxeFloat.to_string(((case 1000000000 do
      std_random_max when std_random_max <= 0 -> 0
      std_random_max -> (:rand.uniform(std_random_max) - 1)
    end)))
    conn = Phoenix.ConnTest.build_conn()
    conn = Phoenix.ConnTest.post(conn, "/auth/demo", %{name: "Recent Chat User", email: "recent-chat-" <> run_id <> "@example.test"})
    mounted = Phoenix.LiveViewTest.live(conn, "/todos")
    lv = elem(mounted, 1)
    Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(0)})
    Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(1)})
    Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(2)})
    Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(3)})
    Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(4)})
    Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(5)})
    Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(6)})
    html = Phoenix.LiveViewTest.render(lv)
    condition = StringTools.haxe_index_of(html, "Recent note " <> run_id <> "-6", 0) != -1
    assert condition
    condition = StringTools.haxe_index_of(html, "Recent note " <> run_id <> "-1", 0) != -1
    assert condition
    condition = StringTools.haxe_index_of(html, "Recent note " <> run_id <> "-0", 0) == -1
    assert condition
  end
end
