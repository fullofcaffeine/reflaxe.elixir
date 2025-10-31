defmodule Phoenix.HttpStatus do
  def ok() do
    {:ok}
  end
  def created() do
    {:created}
  end
  def no_content() do
    {:no_content}
  end
  def moved_permanently() do
    {:moved_permanently}
  end
  def found() do
    {:found}
  end
  def not_modified() do
    {:not_modified}
  end
  def bad_request() do
    {:bad_request}
  end
  def unauthorized() do
    {:unauthorized}
  end
  def forbidden() do
    {:forbidden}
  end
  def not_found() do
    {:not_found}
  end
  def method_not_allowed() do
    {:method_not_allowed}
  end
  def unprocessable_entity() do
    {:unprocessable_entity}
  end
  def internal_server_error() do
    {:internal_server_error}
  end
  def bad_gateway() do
    {:bad_gateway}
  end
  def service_unavailable() do
    {:service_unavailable}
  end
  def custom(arg0) do
    {:custom, arg0}
  end
end
