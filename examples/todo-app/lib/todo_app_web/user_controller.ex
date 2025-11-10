defmodule TodoAppWeb.UserController do
  use TodoAppWeb, :controller
  def index(conn, value) do
    users = TodoApp.Users.list_users(nil)
    Phoenix.Controller.json(conn, %{:users => users})
  end
  def show(conn, params) do
    user_id = String.to_integer(params.id)
    user = TodoApp.Users.get_user_safe(user_id)
    if (not Kernel.is_nil(user)) do
      Phoenix.Controller.json(conn, %{:user => user})
    else
      this1 = Plug.Conn.put_status(conn, 404)
      Phoenix.Controller.json(this1, %{:error => "User not found"})
    end
  end
  def create(conn, params) do
    (case TodoApp.Users.create_user(params) do
      {:ok, value} ->
        this1 = Plug.Conn.put_status(conn, 201)
        Phoenix.Controller.json(this1, %{:user => value, :created => true, :message => "User created successfully"})
      {:error, reason} ->
        this1 = Plug.Conn.put_status(conn, 422)
        Phoenix.Controller.json(this1, %{:error => "Failed to create user", :changeset => reason})
    end)
  end
  def update(conn, params) do
    user_id = String.to_integer(params.id)
    user = TodoApp.Users.get_user_safe(user_id)
    if (Kernel.is_nil(user)) do
      this1 = Plug.Conn.put_status(conn, 404)
      Phoenix.Controller.json(this1, %{:error => "User not found"})
    end
    update_attrs = %{:name => params.name, :email => params.email, :age => params.age, :active => params.active}
    (case TodoApp.Users.update_user(user, update_attrs) do
      {:ok, value} ->
        payload = %{:user => value, :updated => true, :message => "User " <> params.id <> " updated successfully"}
        Phoenix.Controller.json(conn, payload)
      {:error, reason} ->
        this1 = Plug.Conn.put_status(conn, 422)
        Phoenix.Controller.json(this1, %{:error => "Failed to update user", :changeset => reason})
    end)
  end
  def delete(conn, params) do
    user_id = String.to_integer(params.id)
    user = TodoApp.Users.get_user_safe(user_id)
    if (Kernel.is_nil(user)) do
      this1 = Plug.Conn.put_status(conn, 404)
      Phoenix.Controller.json(this1, %{:error => "User not found"})
    end
    (case TodoApp.Users.delete_user(user) do
      {:ok, value} ->
        payload = %{:deleted => params.id, :success => true, :message => "User " <> params.id <> " deleted successfully"}
        Phoenix.Controller.json(conn, payload)
      {:error, reason} ->
        this1 = Plug.Conn.put_status(conn, 500)
        Phoenix.Controller.json(this1, %{:error => "Failed to delete user", :success => false})
    end)
  end
end
