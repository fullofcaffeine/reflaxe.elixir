defmodule TodoAppWeb.UserController do
  @compile [{:nowarn_unused_function, [{:_generate_unique_id, 0}]}]

  use TodoAppWeb, :controller
  defp _generate_unique_id() do
    timestamp = Date_Impl_.get_time(DateTime.utc_now())
    v = :rand.uniform() * 10000
    random = floor(v)
    "" <> Kernel.to_string(timestamp) <> "_" <> Kernel.to_string(random)
  end
  def index(conn, params) do
    users = Users.list_users(nil)
    Phoenix.Controller.json(conn, %{:users => users})
  end
  def show(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user != nil) do
      Phoenix.Controller.json(conn, %{:user => user})
    else
      this1 = Plug.Conn.put_status(conn, 404)
      Phoenix.Controller.json(this1, %{:error => "User not found"})
    end
  end
  def create(conn, params) do
    result = Users.create_user(params)
    case (result) do
      {:ok, g} ->
        user = g
        this1 = Plug.Conn.put_status(conn, 201)
        Phoenix.Controller.json(this1, %{:user => user, :created => true, :message => "User created successfully"})
      {:error, g} ->
        changeset = g
        this1 = Plug.Conn.put_status(conn, 422)
        Phoenix.Controller.json(this1, %{:error => "Failed to create user", :changeset => changeset})
    end
  end
  def update(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user == nil) do
      this1 = Plug.Conn.put_status(conn, 404)
      Phoenix.Controller.json(this1, %{:error => "User not found"})
    end
    update_attrs = %{:name => params.name, :email => params.email, :age => params.age, :active => params.active}
    result = Users.update_user(user, update_attrs)
    case (result) do
      {:ok, g} ->
        updated_user = g
        data = %{:user => updated_user, :updated => true, :message => "User " <> params.id <> " updated successfully"}
        Phoenix.Controller.json(conn, data)
      {:error, g} ->
        changeset = g
        this1 = Plug.Conn.put_status(conn, 422)
        Phoenix.Controller.json(this1, %{:error => "Failed to update user", :changeset => changeset})
    end
  end
  def delete(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user == nil) do
      this1 = Plug.Conn.put_status(conn, 404)
      Phoenix.Controller.json(this1, %{:error => "User not found"})
    end
    result = Users.delete_user(user)
    case (result) do
      {:ok, g} ->
        _deleted_user = g
        data = %{:deleted => params.id, :success => true, :message => "User " <> params.id <> " deleted successfully"}
        Phoenix.Controller.json(conn, data)
      {:error, g} ->
        _changeset = g
        this1 = Plug.Conn.put_status(conn, 500)
        Phoenix.Controller.json(this1, %{:error => "Failed to delete user", :success => false})
    end
  end
end