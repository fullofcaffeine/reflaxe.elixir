defmodule plug.HttpMethod do
  def get() do
    {:GET}
  end
  def post() do
    {:POST}
  end
  def put() do
    {:PUT}
  end
  def patch() do
    {:PATCH}
  end
  def delete() do
    {:DELETE}
  end
  def head() do
    {:HEAD}
  end
  def options() do
    {:OPTIONS}
  end
end