defmodule TodoAppWeb.UserController do
  use TodoAppWeb, :controller
  defp generate_unique_id() do
    timestamp = Date_Impl_.get_time(DateTime.utc_now())
    v = Math.random() * 10000
    i = Std.int(v)
    random = if v < 0 && v != i, do: (i - 1), else: i
    "" <> Kernel.to_string(timestamp) <> "_" <> Kernel.to_string(random)
  end
  def index(_conn, _params) do
    users = Users.list_users(nil)
    Phoenix.Controller.json(conn, %{:users => users})
  end
  def show(_conn, _params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user != nil) do
      Phoenix.Controller.json(conn, %{:user => user})
    else
      this1 = Plug.Conn.put_status(conn, 404)
      Phoenix.Controller.json(this1, %{:error => "User not found"})
    end
  end
  def create(_conn, _params) do
    result = Users.create_user(params)
    case (result) do
      {:ok, value} ->
        g = elem(result, 1)
        user = value
        this1 = Plug.Conn.put_status(conn, 201)
        Phoenix.Controller.json(this1, %{:user => value, :created => true, :message => "User created successfully"})
      {:error, reason} ->
        g = elem(result, 1)
        changeset = reason
        this1 = Plug.Conn.put_status(conn, 422)
        Phoenix.Controller.json(this1, %{:error => "Failed to create user", :changeset => reason})
    end
  end
  def update(_conn, _params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user == nil) do
      this1 = Plug.Conn.put_status(conn, 404)
      Phoenix.Controller.json(this1, %{:error => "User not found"})
    end
    update_attrs = %{:name => params.name, :email => params.email, :age => params.age, :active => params.active}
    result = Users.update_user(user, update_attrs)
    case (result) do
      {:ok, value} ->
        g = elem(result, 1)
        updated_user = value
        data = %{:user => value, :updated => true, :message => "User " <> params.id <> " updated successfully"}
        Phoenix.Controller.json(conn, data)
      {:error, reason} ->
        g = elem(result, 1)
        changeset = reason
        this1 = Plug.Conn.put_status(conn, 422)
        Phoenix.Controller.json(this1, %{:error => "Failed to update user", :changeset => reason})
    end
  end
  def delete(_conn, _params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user == nil) do
      this1 = Plug.Conn.put_status(conn, 404)
      Phoenix.Controller.json(this1, %{:error => "User not found"})
    end
    result = Users.delete_user(user)
    case (result) do
      {:ok, value} ->
        g = elem(result, 1)
        _deleted_user = value
        data = %{:deleted => params.id, :success => true, :message => "User " <> params.id <> " deleted successfully"}
        Phoenix.Controller.json(conn, data)
      {:error, reason} ->
        g = elem(result, 1)
        _changeset = reason
        this1 = Plug.Conn.put_status(conn, 500)
        Phoenix.Controller.json(this1, %{:error => "Failed to delete user", :success => false})
    end
  end
end