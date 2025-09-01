defmodule TodoAppWeb.UserController do
  use TodoAppWeb, :controller
  defp generate_unique_id() do
    Integer.to_string(System.unique_integer([:positive]))
  end
  def index(conn, params) do
    Phoenix.Controller.json(conn, %{:users => []})
  end
  def show(conn, params) do
    data = %{:user => %{:id => params.id, :name => "User " <> params.id, :email => "user" <> params.id <> "@example.com"}}
    Phoenix.Controller.json(conn, data)
  end
  def create(conn, params) do
    data = %{:user => %{:id => generate_unique_id(), :name => params.name, :email => params.email, :age => params.age}, :created => true, :message => "User created successfully"}
    Phoenix.Controller.json(conn, data)
  end
  def update(conn, params) do
    data = %{:user => %{:id => params.id, :name => (if (params.name != nil), do: params.name, else: "Existing Name"), :email => (if (params.email != nil), do: params.email, else: "existing@email.com"), :age => params.age}, :updated => true, :message => "User " <> params.id <> " updated successfully"}
    Phoenix.Controller.json(conn, data)
  end
  def delete(conn, params) do
    data = %{:deleted => params.id, :success => true, :message => "User " <> params.id <> " deleted successfully"}
    Phoenix.Controller.json(conn, data)
  end
end