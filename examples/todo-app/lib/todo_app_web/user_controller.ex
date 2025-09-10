defmodule TodoAppWeb.UserController do
  use TodoAppWeb, :controller
  defp generate_unique_id() do
    timestamp = Date_Impl_.get_time(DateTime.utc_now())
    v = Math.random() * 10000
    i = Std.int(v)
    random = if v < 0 && v != i, do: (i - 1), else: i
    "" <> Kernel.to_string(timestamp) <> "_" <> Kernel.to_string(random)
  end
  def index(conn, _params) do
    Phoenix.Controller.json(conn, %{:users => users})
  end
  def show(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user != nil) do
      Phoenix.Controller.json(conn, %{:user => user})
    else
      Phoenix.Controller.json(this1, %{:error => "User not found"})
    end
  end
  def create(_conn, _params) do
    case (result) do
      {:ok, _} ->
        Phoenix.Controller.json(this1, %{:user => user, :created => true, :message => "User created successfully"})
      {:error, _} ->
        Phoenix.Controller.json(this1, %{:error => "Failed to create user", :changeset => changeset})
    end
  end
  def update(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user == nil) do
      Phoenix.Controller.json(this1, %{:error => "User not found"})
    end
    update_attrs = %{:name => params.name, :email => params.email, :age => params.age, :active => params.active}
    result = Users.update_user(user, update_attrs)
    case (result) do
      {:ok, _} ->
        Phoenix.Controller.json(conn, data)
      {:error, _} ->
        Phoenix.Controller.json(this1, %{:error => "Failed to update user", :changeset => changeset})
    end
  end
  def delete(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user == nil) do
      Phoenix.Controller.json(this1, %{:error => "User not found"})
    end
    result = Users.delete_user(user)
    case (result) do
      {:ok, _} ->
        Phoenix.Controller.json(conn, data)
      {:error, _} ->
        Phoenix.Controller.json(this1, %{:error => "Failed to delete user", :success => false})
    end
  end
end