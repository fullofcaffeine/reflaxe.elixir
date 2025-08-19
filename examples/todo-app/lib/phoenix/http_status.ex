defmodule HttpStatus do
  @moduledoc """
  HttpStatus enum generated from Haxe
  
  
   * HTTP status codes with semantic meaning
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :ok |
    :created |
    :no_content |
    :moved_permanently |
    :found |
    :not_modified |
    :bad_request |
    :unauthorized |
    :forbidden |
    :not_found |
    :method_not_allowed |
    :unprocessable_entity |
    :internal_server_error |
    :bad_gateway |
    :service_unavailable |
    {:custom, term()}

  @doc "Creates ok enum value"
  @spec ok() :: :ok
  def ok(), do: :ok

  @doc "Creates created enum value"
  @spec created() :: :created
  def created(), do: :created

  @doc "Creates no_content enum value"
  @spec no_content() :: :no_content
  def no_content(), do: :no_content

  @doc "Creates moved_permanently enum value"
  @spec moved_permanently() :: :moved_permanently
  def moved_permanently(), do: :moved_permanently

  @doc "Creates found enum value"
  @spec found() :: :found
  def found(), do: :found

  @doc "Creates not_modified enum value"
  @spec not_modified() :: :not_modified
  def not_modified(), do: :not_modified

  @doc "Creates bad_request enum value"
  @spec bad_request() :: :bad_request
  def bad_request(), do: :bad_request

  @doc "Creates unauthorized enum value"
  @spec unauthorized() :: :unauthorized
  def unauthorized(), do: :unauthorized

  @doc "Creates forbidden enum value"
  @spec forbidden() :: :forbidden
  def forbidden(), do: :forbidden

  @doc "Creates not_found enum value"
  @spec not_found() :: :not_found
  def not_found(), do: :not_found

  @doc "Creates method_not_allowed enum value"
  @spec method_not_allowed() :: :method_not_allowed
  def method_not_allowed(), do: :method_not_allowed

  @doc "Creates unprocessable_entity enum value"
  @spec unprocessable_entity() :: :unprocessable_entity
  def unprocessable_entity(), do: :unprocessable_entity

  @doc "Creates internal_server_error enum value"
  @spec internal_server_error() :: :internal_server_error
  def internal_server_error(), do: :internal_server_error

  @doc "Creates bad_gateway enum value"
  @spec bad_gateway() :: :bad_gateway
  def bad_gateway(), do: :bad_gateway

  @doc "Creates service_unavailable enum value"
  @spec service_unavailable() :: :service_unavailable
  def service_unavailable(), do: :service_unavailable

  @doc """
  Creates custom enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec custom(term()) :: {:custom, term()}
  def custom(arg0) do
    {:custom, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is ok variant"
  @spec is_ok(t()) :: boolean()
  def is_ok(:ok), do: true
  def is_ok(_), do: false

  @doc "Returns true if value is created variant"
  @spec is_created(t()) :: boolean()
  def is_created(:created), do: true
  def is_created(_), do: false

  @doc "Returns true if value is no_content variant"
  @spec is_no_content(t()) :: boolean()
  def is_no_content(:no_content), do: true
  def is_no_content(_), do: false

  @doc "Returns true if value is moved_permanently variant"
  @spec is_moved_permanently(t()) :: boolean()
  def is_moved_permanently(:moved_permanently), do: true
  def is_moved_permanently(_), do: false

  @doc "Returns true if value is found variant"
  @spec is_found(t()) :: boolean()
  def is_found(:found), do: true
  def is_found(_), do: false

  @doc "Returns true if value is not_modified variant"
  @spec is_not_modified(t()) :: boolean()
  def is_not_modified(:not_modified), do: true
  def is_not_modified(_), do: false

  @doc "Returns true if value is bad_request variant"
  @spec is_bad_request(t()) :: boolean()
  def is_bad_request(:bad_request), do: true
  def is_bad_request(_), do: false

  @doc "Returns true if value is unauthorized variant"
  @spec is_unauthorized(t()) :: boolean()
  def is_unauthorized(:unauthorized), do: true
  def is_unauthorized(_), do: false

  @doc "Returns true if value is forbidden variant"
  @spec is_forbidden(t()) :: boolean()
  def is_forbidden(:forbidden), do: true
  def is_forbidden(_), do: false

  @doc "Returns true if value is not_found variant"
  @spec is_not_found(t()) :: boolean()
  def is_not_found(:not_found), do: true
  def is_not_found(_), do: false

  @doc "Returns true if value is method_not_allowed variant"
  @spec is_method_not_allowed(t()) :: boolean()
  def is_method_not_allowed(:method_not_allowed), do: true
  def is_method_not_allowed(_), do: false

  @doc "Returns true if value is unprocessable_entity variant"
  @spec is_unprocessable_entity(t()) :: boolean()
  def is_unprocessable_entity(:unprocessable_entity), do: true
  def is_unprocessable_entity(_), do: false

  @doc "Returns true if value is internal_server_error variant"
  @spec is_internal_server_error(t()) :: boolean()
  def is_internal_server_error(:internal_server_error), do: true
  def is_internal_server_error(_), do: false

  @doc "Returns true if value is bad_gateway variant"
  @spec is_bad_gateway(t()) :: boolean()
  def is_bad_gateway(:bad_gateway), do: true
  def is_bad_gateway(_), do: false

  @doc "Returns true if value is service_unavailable variant"
  @spec is_service_unavailable(t()) :: boolean()
  def is_service_unavailable(:service_unavailable), do: true
  def is_service_unavailable(_), do: false

  @doc "Returns true if value is custom variant"
  @spec is_custom(t()) :: boolean()
  def is_custom({:custom, _}), do: true
  def is_custom(_), do: false

  @doc "Extracts value from custom variant, returns {:ok, value} or :error"
  @spec get_custom_value(t()) :: {:ok, term()} | :error
  def get_custom_value({:custom, value}), do: {:ok, value}
  def get_custom_value(_), do: :error

end
