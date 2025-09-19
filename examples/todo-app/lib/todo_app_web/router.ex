defmodule TodoAppWeb.Router do
  def root() do
    "/"
  end
  def todos_index() do
    "/todos"
  end
  def todos_show() do
    "/todos/:id"
  end
  def todos_edit() do
    "/todos/:id/edit"
  end
  def api_users() do
    "/api/users"
  end
  def api_create_user() do
    "/api/users"
  end
  def api_update_user() do
    "/api/users/:id"
  end
  def api_delete_user() do
    "/api/users/:id"
  end
  def dashboard() do
    "/dev/dashboard"
  end
end