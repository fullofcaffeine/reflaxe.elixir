defmodule Phoenix.HttpStatus do
  def ok() do
    {0}
  end
  def created() do
    {1}
  end
  def no_content() do
    {2}
  end
  def moved_permanently() do
    {3}
  end
  def found() do
    {4}
  end
  def not_modified() do
    {5}
  end
  def bad_request() do
    {6}
  end
  def unauthorized() do
    {7}
  end
  def forbidden() do
    {8}
  end
  def not_found() do
    {9}
  end
  def method_not_allowed() do
    {10}
  end
  def unprocessable_entity() do
    {11}
  end
  def internal_server_error() do
    {12}
  end
  def bad_gateway() do
    {13}
  end
  def service_unavailable() do
    {14}
  end
  def custom(arg0) do
    {15, arg0}
  end
end