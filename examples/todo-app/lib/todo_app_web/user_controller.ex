defmodule TodoAppWeb.UserController do
  use TodoAppWeb, :controller
  defp generate_unique_id() do
    Integer.to_string(System.unique_integer([:positive]))
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
      this_1 = Plug.Conn.put_status(conn, 404)
      Phoenix.Controller.json(this_1, %{:error => "User not found"})
    end
  end
  def create(conn, params) do
    result = Users.create_user(params)
    if (result[:status] == "ok") do
      this_1 = Plug.Conn.put_status(conn, 201)
      data = %{:user => result[:user], :created => true, :message => "User created successfully"}
      Phoenix.Controller.json(this_1, data)
    else
      this_1 = Plug.Conn.put_status(conn, 422)
      data = %{:error => "Failed to create user", :changeset => result[:changeset]}
      Phoenix.Controller.json(this_1, data)
    end
  end
  def update(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user == nil) do
      this_1 = Plug.Conn.put_status(conn, 404)
      Phoenix.Controller.json(this_1, %{:error => "User not found"})
    end
    update_attrs = %{}
    if (params.name != nil) do
      Reflect.set_field(update_attrs, "name", params.name)
    end
    if (params.email != nil) do
      Reflect.set_field(update_attrs, "email", params.email)
    end
    if (params.age != nil) do
      Reflect.set_field(update_attrs, "age", params.age)
    end
    result = Users.update_user(user, update_attrs)
    if (result[:status] == "ok") do
      data = %{:user => result[:user], :updated => true, :message => "User " <> params.id <> " updated successfully"}
      Phoenix.Controller.json(conn, data)
    else
      this_1 = Plug.Conn.put_status(conn, 422)
      data = %{:error => "Failed to update user", :changeset => result[:changeset]}
      Phoenix.Controller.json(this_1, data)
    end
  end
  def delete(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user == nil) do
      this_1 = Plug.Conn.put_status(conn, 404)
      Phoenix.Controller.json(this_1, %{:error => "User not found"})
    end
    result = Users.delete_user(user)
    if (result[:status] == "ok") do
      data = %{:deleted => params.id, :success => true, :message => "User " <> params.id <> " deleted successfully"}
      Phoenix.Controller.json(conn, data)
    else
      this_1 = Plug.Conn.put_status(conn, 500)
      Phoenix.Controller.json(this_1, %{:error => "Failed to delete user", :success => false})
    end
  end
end