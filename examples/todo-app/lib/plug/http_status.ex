defmodule plug.HttpStatus do
  def ok() do
    {:Ok}
  end
  def created() do
    {:Created}
  end
  def no_content() do
    {:NoContent}
  end
  def bad_request() do
    {:BadRequest}
  end
  def unauthorized() do
    {:Unauthorized}
  end
  def forbidden() do
    {:Forbidden}
  end
  def not_found() do
    {:NotFound}
  end
  def method_not_allowed() do
    {:MethodNotAllowed}
  end
  def internal_server_error() do
    {:InternalServerError}
  end
  def custom(arg0) do
    {:Custom, arg0}
  end
end