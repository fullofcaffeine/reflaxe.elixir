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
    _ = Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: body})
    html = Phoenix.LiveViewTest.render(lv)
    condition = (case :binary.match(html, body) do
  {pos, _} -> pos
  :nomatch -> -1
end) != -1
    assert condition
    condition = (case :binary.match(html, "Room note persisted through Ecto") do
  {pos, _} -> pos
  :nomatch -> -1
end) != -1
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
    _ = Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(0)})
    _ = Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(1)})
    _ = Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(2)})
    _ = Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(3)})
    _ = Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(4)})
    _ = Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(5)})
    _ = Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(lv, "form[phx-submit='create_chat_message']"), %{body: "Recent note " <> run_id <> "-" <> Reflaxe.Elixir.HaxeFloat.to_string(6)})
    html = Phoenix.LiveViewTest.render(lv)
    condition = (case :binary.match(html, "Recent note " <> run_id <> "-6") do
  {pos, _} -> pos
  :nomatch -> -1
end) != -1
    assert condition
    condition = (case :binary.match(html, "Recent note " <> run_id <> "-1") do
  {pos, _} -> pos
  :nomatch -> -1
end) != -1
    assert condition
    condition = (case :binary.match(html, "Recent note " <> run_id <> "-0") do
  {pos, _} -> pos
  :nomatch -> -1
end) == -1
    assert condition
  end
end
