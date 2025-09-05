defmodule Phoenix.HttpStatus do
  def ok() do
    {:Ok}
  end
  def created() do
    {:Created}
  end
  def no_content() do
    {:NoContent}
  end
  def moved_permanently() do
    {:MovedPermanently}
  end
  def found() do
    {:Found}
  end
  def not_modified() do
    {:NotModified}
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
  def unprocessable_entity() do
    {:UnprocessableEntity}
  end
  def internal_server_error() do
    {:InternalServerError}
  end
  def bad_gateway() do
    {:BadGateway}
  end
  def service_unavailable() do
    {:ServiceUnavailable}
  end
  def custom(arg0) do
    {:Custom, arg0}
  end
end