defmodule Plug.HttpStatus do
  def ok() do
    {0}
  end
  def created() do
    {1}
  end
  def no_content() do
    {2}
  end
  def bad_request() do
    {3}
  end
  def unauthorized() do
    {4}
  end
  def forbidden() do
    {5}
  end
  def not_found() do
    {6}
  end
  def method_not_allowed() do
    {7}
  end
  def internal_server_error() do
    {8}
  end
  def custom(arg0) do
    {9, arg0}
  end
end