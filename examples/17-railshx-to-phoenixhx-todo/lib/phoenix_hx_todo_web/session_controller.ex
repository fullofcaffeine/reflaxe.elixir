defmodule PhoenixHxTodoWeb.SessionController do
  use PhoenixHxTodoWeb, :controller
  def create(conn, params) do
    name = string_param(params, "name", "Guest Workspace")
    email = string_param(params, "email", "guest@example.test")
    if (StringTools.ltrim(StringTools.rtrim(name)) == "" or StringTools.ltrim(StringTools.rtrim(email)) == "") do
      this1 = Phoenix.Controller.put_flash(conn, "error", "Name and email are required.")
      Phoenix.Controller.redirect(this1, to: "/")
    else
      (case PhoenixHxTodo.Accounts.get_or_create_demo_user(name, email) do
        {:ok, user} ->
          _ = PhoenixHxTodo.Todos.seed_defaults_for_user(user)
          value = user.id
          this1 = Plug.Conn.put_session(conn, String.to_atom("user_id"), value)
          message = "Signed in as #{user.name}."
          this1 = Phoenix.Controller.put_flash(this1, "info", message)
          Phoenix.Controller.redirect(this1, to: "/todos")
        {:error, _} ->
          this1 = Phoenix.Controller.put_flash(conn, "error", "Could not open the demo workspace.")
          Phoenix.Controller.redirect(this1, to: "/")
      end)
    end
  end
  def delete(conn, _params) do
    this1 = Plug.Conn.delete_session(conn, String.to_atom("user_id"))
    this1 = Phoenix.Controller.put_flash(this1, "info", "Signed out.")
    Phoenix.Controller.redirect(this1, to: "/")
  end
  defp string_param(params, key, fallback) do
    PhoenixHx.Params.get_string_default(params, key, fallback)
  end
end
