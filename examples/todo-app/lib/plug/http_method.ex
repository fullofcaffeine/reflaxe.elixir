defmodule Plug.HttpMethod do
  def get() do
    {0}
  end
  def post() do
    {1}
  end
  def put() do
    {2}
  end
  def patch() do
    {3}
  end
  def delete() do
    {4}
  end
  def head() do
    {5}
  end
  def options() do
    {6}
  end
end