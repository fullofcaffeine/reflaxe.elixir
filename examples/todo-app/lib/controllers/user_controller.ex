defmodule UserController do
  def index() do
    fn -> "User index" end
  end
  def show() do
    fn -> "User show" end
  end
  def create() do
    fn -> "User create" end
  end
  def update() do
    fn -> "User update" end
  end
  def delete() do
    fn -> "User delete" end
  end
end