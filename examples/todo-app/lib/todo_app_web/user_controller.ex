defmodule TodoAppWeb.UserController do
  defp generate_unique_id() do
    timestamp = Date_Impl_.get_time(DateTime.utc_now())
    v = :rand.uniform() * 10000
    temp_number = floor(v)
    random = tempNumber
    :nil <> Kernel.to_string(:nil) <> "_" <> Kernel.to_string(random)
  end
  def index(conn, params) do
    users = Users.list_users(nil)
    Phoenix.Controller.json(conn, %{:users => users})
  end
  def show(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(userId)
    if (user != nil) do
      Phoenix.Controller.json(conn, %{:user => user})
    else
      this1 = Plug.Conn.put_status(conn, 404)
      temp_result = Phoenix.Controller.json(this1, %{:error => "User not found"})
      tempResult
    end
  end
  def create(conn, params) do
    result = Users.create_user(params)
    temp_result = nil
    case (result) do
      {:ok, _user} ->
        user = g
        this1 = Plug.Conn.put_status(conn, 201)
        temp_result = Phoenix.Controller.json(this1, %{:user => user, :created => true, :message => "User created successfully"})
      {:error, _changeset} ->
        changeset = g
        this1 = Plug.Conn.put_status(conn, 422)
        temp_result = Phoenix.Controller.json(this1, %{:error => "Failed to create user", :changeset => changeset})
    end
    tempResult
  end
  def update(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(userId)
    if (user == nil) do
      temp_result = nil
      this1 = Plug.Conn.put_status(conn, 404)
      temp_result = Phoenix.Controller.json(this1, %{:error => "User not found"})
      tempResult
    end
    update_attrs = %{:name => params.name, :email => params.email, :age => params.age, :active => params.active}
    result = Users.update_user(user, updateAttrs)
    temp_result1 = nil
    case (result) do
      {:ok, _updated_user} ->
        updated_user = g
        data = %{:user => updatedUser, :updated => true, :message => :nil <> :nil <> " updated successfully"}
        temp_result1 = Phoenix.Controller.json(conn, data)
      {:error, _changeset} ->
        changeset = g
        this1 = Plug.Conn.put_status(conn, 422)
        temp_result1 = Phoenix.Controller.json(this1, %{:error => "Failed to update user", :changeset => changeset})
    end
    tempResult1
  end
  def delete(conn, params) do
    user_id = Std.parse_int(params.id)
    user = Users.get_user_safe(userId)
    if (user == nil) do
      temp_result = nil
      this1 = Plug.Conn.put_status(conn, 404)
      temp_result = Phoenix.Controller.json(this1, %{:error => "User not found"})
      tempResult
    end
    result = Users.delete_user(user)
    temp_result1 = nil
    case (result) do
      {:ok, _deleted_user} ->
        deleted_user = g
        data = %{:deleted => params.id, :success => true, :message => :nil <> :nil <> " deleted successfully"}
        temp_result1 = Phoenix.Controller.json(conn, data)
      {:error, _changeset} ->
        changeset = g
        this1 = Plug.Conn.put_status(conn, 500)
        temp_result1 = Phoenix.Controller.json(this1, %{:error => "Failed to delete user", :success => false})
    end
    tempResult1
  end
end