defmodule TodoAppWeb.UserController do
  defp generate_unique_id() do
    timestamp = Date_Impl_.get_time(DateTime.utc_now())
    v = :rand.uniform() * 10000
    temp_number = floor(v)
    random = temp_number
    "" <> timestamp.to_string() <> "_" <> random.to_string()
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
      temp_result = Phoenix.Controller.json(this1, %{:error => "User not found"})
      temp_result
    end
  end
  def create(conn, params) do
    result = Users.create_user(params)
    temp_result = nil
    case (result) do
      {:ok, user} ->
        user = g
        this1 = Plug.Conn.put_status(conn, 201)
        temp_result = Phoenix.Controller.json(this1, %{:user => user, :created => true, :message => "User created successfully"})
      {:error, changeset} ->
        changeset = g
        this1 = Plug.Conn.put_status(conn, 422)
        temp_result = Phoenix.Controller.json(this1, %{:error => "Failed to create user", :changeset => changeset})
    end
    temp_result
  end
  def update(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user == nil) do
      temp_result = nil
      this1 = Plug.Conn.put_status(conn, 404)
      temp_result = Phoenix.Controller.json(this1, %{:error => "User not found"})
      temp_result
    end
    update_attrs = %{:name => params.name, :email => params.email, :age => params.age, :active => params.active}
    result = Users.update_user(user, update_attrs)
    temp_result1 = nil
    case (result) do
      {:ok, updated_user} ->
        updated_user = g
        data = %{:user => updated_user, :updated => true, :message => "User " <> params.id <> " updated successfully"}
        temp_result1 = Phoenix.Controller.json(conn, data)
      {:error, changeset} ->
        changeset = g
        this1 = Plug.Conn.put_status(conn, 422)
        temp_result1 = Phoenix.Controller.json(this1, %{:error => "Failed to update user", :changeset => changeset})
    end
    temp_result1
  end
  def delete(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(user_id)
    if (user == nil) do
      temp_result = nil
      this1 = Plug.Conn.put_status(conn, 404)
      temp_result = Phoenix.Controller.json(this1, %{:error => "User not found"})
      temp_result
    end
    result = Users.delete_user(user)
    temp_result1 = nil
    case (result) do
      {:ok, deleted_user} ->
        deleted_user = g
        data = %{:deleted => params.id, :success => true, :message => "User " <> params.id <> " deleted successfully"}
        temp_result1 = Phoenix.Controller.json(conn, data)
      {:error, changeset} ->
        changeset = g
        this1 = Plug.Conn.put_status(conn, 500)
        temp_result1 = Phoenix.Controller.json(this1, %{:error => "Failed to delete user", :success => false})
    end
    temp_result1
  end
end