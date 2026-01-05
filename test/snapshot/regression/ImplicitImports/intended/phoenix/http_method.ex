defmodule Phoenix.HttpMethod do
  def get() do
    {:get}
  end
  def post() do
    {:post}
  end
  def put() do
    {:put}
  end
  def patch() do
    {:patch}
  end
  def delete() do
    {:delete}
  end
  def head() do
    {:head}
  end
  def options() do
    {:options}
  end
end
