defmodule TodoAppRouter do
  def root() do
    "/"
  end
  def todosIndex() do
    "/todos"
  end
  def todosShow() do
    "/todos/:id"
  end
  def todosEdit() do
    "/todos/:id/edit"
  end
  def apiUsers() do
    "/api/users"
  end
  def apiCreateUser() do
    "/api/users"
  end
  def apiUpdateUser() do
    "/api/users/:id"
  end
  def apiDeleteUser() do
    "/api/users/:id"
  end
  def dashboard() do
    "/dev/dashboard"
  end
end