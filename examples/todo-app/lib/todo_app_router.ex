defmodule TodoAppRouter do
  def root() do
    fn -> "/" end
  end
  def todosIndex() do
    fn -> "/todos" end
  end
  def todosShow() do
    fn -> "/todos/:id" end
  end
  def todosEdit() do
    fn -> "/todos/:id/edit" end
  end
  def apiUsers() do
    fn -> "/api/users" end
  end
  def apiCreateUser() do
    fn -> "/api/users" end
  end
  def apiUpdateUser() do
    fn -> "/api/users/:id" end
  end
  def apiDeleteUser() do
    fn -> "/api/users/:id" end
  end
  def dashboard() do
    fn -> "/dev/dashboard" end
  end
end