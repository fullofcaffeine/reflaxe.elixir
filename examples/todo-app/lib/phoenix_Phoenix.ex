defmodule HttpMethod do
  @moduledoc """
  HttpMethod enum generated from Haxe
  
  
 * HTTP methods enum
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :g_e_t |
    :p_o_s_t |
    :p_u_t |
    :p_a_t_c_h |
    :d_e_l_e_t_e |
    :h_e_a_d |
    :o_p_t_i_o_n_s

  @doc "Creates g_e_t enum value"
  @spec g_e_t() :: :g_e_t
  def g_e_t(), do: :g_e_t

  @doc "Creates p_o_s_t enum value"
  @spec p_o_s_t() :: :p_o_s_t
  def p_o_s_t(), do: :p_o_s_t

  @doc "Creates p_u_t enum value"
  @spec p_u_t() :: :p_u_t
  def p_u_t(), do: :p_u_t

  @doc "Creates p_a_t_c_h enum value"
  @spec p_a_t_c_h() :: :p_a_t_c_h
  def p_a_t_c_h(), do: :p_a_t_c_h

  @doc "Creates d_e_l_e_t_e enum value"
  @spec d_e_l_e_t_e() :: :d_e_l_e_t_e
  def d_e_l_e_t_e(), do: :d_e_l_e_t_e

  @doc "Creates h_e_a_d enum value"
  @spec h_e_a_d() :: :h_e_a_d
  def h_e_a_d(), do: :h_e_a_d

  @doc "Creates o_p_t_i_o_n_s enum value"
  @spec o_p_t_i_o_n_s() :: :o_p_t_i_o_n_s
  def o_p_t_i_o_n_s(), do: :o_p_t_i_o_n_s

  # Predicate functions for pattern matching
  @doc "Returns true if value is g_e_t variant"
  @spec is_g_e_t(t()) :: boolean()
  def is_g_e_t(:g_e_t), do: true
  def is_g_e_t(_), do: false

  @doc "Returns true if value is p_o_s_t variant"
  @spec is_p_o_s_t(t()) :: boolean()
  def is_p_o_s_t(:p_o_s_t), do: true
  def is_p_o_s_t(_), do: false

  @doc "Returns true if value is p_u_t variant"
  @spec is_p_u_t(t()) :: boolean()
  def is_p_u_t(:p_u_t), do: true
  def is_p_u_t(_), do: false

  @doc "Returns true if value is p_a_t_c_h variant"
  @spec is_p_a_t_c_h(t()) :: boolean()
  def is_p_a_t_c_h(:p_a_t_c_h), do: true
  def is_p_a_t_c_h(_), do: false

  @doc "Returns true if value is d_e_l_e_t_e variant"
  @spec is_d_e_l_e_t_e(t()) :: boolean()
  def is_d_e_l_e_t_e(:d_e_l_e_t_e), do: true
  def is_d_e_l_e_t_e(_), do: false

  @doc "Returns true if value is h_e_a_d variant"
  @spec is_h_e_a_d(t()) :: boolean()
  def is_h_e_a_d(:h_e_a_d), do: true
  def is_h_e_a_d(_), do: false

  @doc "Returns true if value is o_p_t_i_o_n_s variant"
  @spec is_o_p_t_i_o_n_s(t()) :: boolean()
  def is_o_p_t_i_o_n_s(:o_p_t_i_o_n_s), do: true
  def is_o_p_t_i_o_n_s(_), do: false

end


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


defmodule FlashType do
  @moduledoc """
  FlashType enum generated from Haxe
  
  
 * Flash message types
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :info |
    :success |
    :warning |
    :error |
    {:custom, term()}

  @doc "Creates info enum value"
  @spec info() :: :info
  def info(), do: :info

  @doc "Creates success enum value"
  @spec success() :: :success
  def success(), do: :success

  @doc "Creates warning enum value"
  @spec warning() :: :warning
  def warning(), do: :warning

  @doc "Creates error enum value"
  @spec error() :: :error
  def error(), do: :error

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
  @doc "Returns true if value is info variant"
  @spec is_info(t()) :: boolean()
  def is_info(:info), do: true
  def is_info(_), do: false

  @doc "Returns true if value is success variant"
  @spec is_success(t()) :: boolean()
  def is_success(:success), do: true
  def is_success(_), do: false

  @doc "Returns true if value is warning variant"
  @spec is_warning(t()) :: boolean()
  def is_warning(:warning), do: true
  def is_warning(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error(:error), do: true
  def is_error(_), do: false

  @doc "Returns true if value is custom variant"
  @spec is_custom(t()) :: boolean()
  def is_custom({:custom, _}), do: true
  def is_custom(_), do: false

  @doc "Extracts value from custom variant, returns {:ok, value} or :error"
  @spec get_custom_value(t()) :: {:ok, term()} | :error
  def get_custom_value({:custom, value}), do: {:ok, value}
  def get_custom_value(_), do: :error

end


defmodule ConnState do
  @moduledoc """
  ConnState enum generated from Haxe
  
  
 * Connection state
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :unset |
    :set |
    :sent |
    :chunked |
    :file_chunked

  @doc "Creates unset enum value"
  @spec unset() :: :unset
  def unset(), do: :unset

  @doc "Creates set enum value"
  @spec set() :: :set
  def set(), do: :set

  @doc "Creates sent enum value"
  @spec sent() :: :sent
  def sent(), do: :sent

  @doc "Creates chunked enum value"
  @spec chunked() :: :chunked
  def chunked(), do: :chunked

  @doc "Creates file_chunked enum value"
  @spec file_chunked() :: :file_chunked
  def file_chunked(), do: :file_chunked

  # Predicate functions for pattern matching
  @doc "Returns true if value is unset variant"
  @spec is_unset(t()) :: boolean()
  def is_unset(:unset), do: true
  def is_unset(_), do: false

  @doc "Returns true if value is set variant"
  @spec is_set(t()) :: boolean()
  def is_set(:set), do: true
  def is_set(_), do: false

  @doc "Returns true if value is sent variant"
  @spec is_sent(t()) :: boolean()
  def is_sent(:sent), do: true
  def is_sent(_), do: false

  @doc "Returns true if value is chunked variant"
  @spec is_chunked(t()) :: boolean()
  def is_chunked(:chunked), do: true
  def is_chunked(_), do: false

  @doc "Returns true if value is file_chunked variant"
  @spec is_file_chunked(t()) :: boolean()
  def is_file_chunked(:file_chunked), do: true
  def is_file_chunked(_), do: false

end


defmodule RouteHelper do
  @moduledoc """
  RouteHelper enum generated from Haxe
  
  
 * Route helper identifier
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:named, term()} |
    {:path, term()}

  @doc """
  Creates named enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec named(term()) :: {:named, term()}
  def named(arg0) do
    {:named, arg0}
  end

  @doc """
  Creates path enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec path(term()) :: {:path, term()}
  def path(arg0) do
    {:path, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is named variant"
  @spec is_named(t()) :: boolean()
  def is_named({:named, _}), do: true
  def is_named(_), do: false

  @doc "Returns true if value is path variant"
  @spec is_path(t()) :: boolean()
  def is_path({:path, _}), do: true
  def is_path(_), do: false

  @doc "Extracts value from named variant, returns {:ok, value} or :error"
  @spec get_named_value(t()) :: {:ok, term()} | :error
  def get_named_value({:named, value}), do: {:ok, value}
  def get_named_value(_), do: :error

  @doc "Extracts value from path variant, returns {:ok, value} or :error"
  @spec get_path_value(t()) :: {:ok, term()} | :error
  def get_path_value({:path, value}), do: {:ok, value}
  def get_path_value(_), do: :error

end


defmodule FormFieldValue do
  @moduledoc """
  FormFieldValue enum generated from Haxe
  
  
 * Form field value types for type-safe form handling
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:string_value, term()} |
    {:int_value, term()} |
    {:float_value, term()} |
    {:bool_value, term()} |
    {:array_value, term()}

  @doc """
  Creates string_value enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec string_value(term()) :: {:string_value, term()}
  def string_value(arg0) do
    {:string_value, arg0}
  end

  @doc """
  Creates int_value enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec int_value(term()) :: {:int_value, term()}
  def int_value(arg0) do
    {:int_value, arg0}
  end

  @doc """
  Creates float_value enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec float_value(term()) :: {:float_value, term()}
  def float_value(arg0) do
    {:float_value, arg0}
  end

  @doc """
  Creates bool_value enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec bool_value(term()) :: {:bool_value, term()}
  def bool_value(arg0) do
    {:bool_value, arg0}
  end

  @doc """
  Creates array_value enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec array_value(term()) :: {:array_value, term()}
  def array_value(arg0) do
    {:array_value, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is string_value variant"
  @spec is_string_value(t()) :: boolean()
  def is_string_value({:string_value, _}), do: true
  def is_string_value(_), do: false

  @doc "Returns true if value is int_value variant"
  @spec is_int_value(t()) :: boolean()
  def is_int_value({:int_value, _}), do: true
  def is_int_value(_), do: false

  @doc "Returns true if value is float_value variant"
  @spec is_float_value(t()) :: boolean()
  def is_float_value({:float_value, _}), do: true
  def is_float_value(_), do: false

  @doc "Returns true if value is bool_value variant"
  @spec is_bool_value(t()) :: boolean()
  def is_bool_value({:bool_value, _}), do: true
  def is_bool_value(_), do: false

  @doc "Returns true if value is array_value variant"
  @spec is_array_value(t()) :: boolean()
  def is_array_value({:array_value, _}), do: true
  def is_array_value(_), do: false

  @doc "Extracts value from string_value variant, returns {:ok, value} or :error"
  @spec get_string_value_value(t()) :: {:ok, term()} | :error
  def get_string_value_value({:string_value, value}), do: {:ok, value}
  def get_string_value_value(_), do: :error

  @doc "Extracts value from int_value variant, returns {:ok, value} or :error"
  @spec get_int_value_value(t()) :: {:ok, term()} | :error
  def get_int_value_value({:int_value, value}), do: {:ok, value}
  def get_int_value_value(_), do: :error

  @doc "Extracts value from float_value variant, returns {:ok, value} or :error"
  @spec get_float_value_value(t()) :: {:ok, term()} | :error
  def get_float_value_value({:float_value, value}), do: {:ok, value}
  def get_float_value_value(_), do: :error

  @doc "Extracts value from bool_value variant, returns {:ok, value} or :error"
  @spec get_bool_value_value(t()) :: {:ok, term()} | :error
  def get_bool_value_value({:bool_value, value}), do: {:ok, value}
  def get_bool_value_value(_), do: :error

  @doc "Extracts value from array_value variant, returns {:ok, value} or :error"
  @spec get_array_value_value(t()) :: {:ok, term()} | :error
  def get_array_value_value({:array_value, value}), do: {:ok, value}
  def get_array_value_value(_), do: :error

end


defmodule MountResult do
  @moduledoc """
  MountResult enum generated from Haxe
  
  
 * LiveView mount return type with full type safety
 * 
 * @param TAssigns The application-specific socket assigns structure type
 * 
 * ## Generic Usage Pattern
 * 
 * Define your assigns structure:
 * ```haxe
 * typedef MyAssigns = {
 *     var user: User;
 *     var todos: Array<Todo>;
 *     var filter: String;
 * }
 * ```
 * 
 * Use in mount function:
 * ```haxe
 * public static function mount(params, session, socket: Socket<MyAssigns>): MountResult<MyAssigns> {
 *     return Ok(socket.assign({user: currentUser, todos: [], filter: "all"}));
 * }
 * ```
 * 
 * ## Type Safety Benefits
 * 
 * - **Compile-time validation**: Invalid assign access caught at compile time
 * - **IntelliSense support**: Full autocomplete for socket.assigns.fieldName
 * - **Refactoring safety**: Rename assigns fields with confidence
 * - **Framework compatibility**: Compiles to standard Phoenix LiveView patterns
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:ok, term()} |
    {:ok_with_temporary_assigns, term(), term()} |
    {:error, term()}

  @doc """
  Creates ok enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec ok(term()) :: {:ok, term()}
  def ok(arg0) do
    {:ok, arg0}
  end

  @doc """
  Creates ok_with_temporary_assigns enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec ok_with_temporary_assigns(term(), term()) :: {:ok_with_temporary_assigns, term(), term()}
  def ok_with_temporary_assigns(arg0, arg1) do
    {:ok_with_temporary_assigns, arg0, arg1}
  end

  @doc """
  Creates error enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec error(term()) :: {:error, term()}
  def error(arg0) do
    {:error, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is ok variant"
  @spec is_ok(t()) :: boolean()
  def is_ok({:ok, _}), do: true
  def is_ok(_), do: false

  @doc "Returns true if value is ok_with_temporary_assigns variant"
  @spec is_ok_with_temporary_assigns(t()) :: boolean()
  def is_ok_with_temporary_assigns({:ok_with_temporary_assigns, _}), do: true
  def is_ok_with_temporary_assigns(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error({:error, _}), do: true
  def is_error(_), do: false

  @doc "Extracts value from ok variant, returns {:ok, value} or :error"
  @spec get_ok_value(t()) :: {:ok, term()} | :error
  def get_ok_value({:ok, value}), do: {:ok, value}
  def get_ok_value(_), do: :error

  @doc "Extracts value from ok_with_temporary_assigns variant, returns {:ok, value} or :error"
  @spec get_ok_with_temporary_assigns_value(t()) :: {:ok, {term(), term()}} | :error
  def get_ok_with_temporary_assigns_value({:ok_with_temporary_assigns, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_ok_with_temporary_assigns_value(_), do: :error

  @doc "Extracts value from error variant, returns {:ok, value} or :error"
  @spec get_error_value(t()) :: {:ok, term()} | :error
  def get_error_value({:error, value}), do: {:ok, value}
  def get_error_value(_), do: :error

end


defmodule HandleEventResult do
  @moduledoc """
  HandleEventResult enum generated from Haxe
  
  
 * Event handling return type with full type safety
 * 
 * @param TAssigns The application-specific socket assigns structure type
 * 
 * ## Generic Usage Pattern
 * 
 * ```haxe
 * public static function handle_event(event: String, params: EventParams, socket: Socket<MyAssigns>): HandleEventResult<MyAssigns> {
 *     return switch (event) {
 *         case "create_todo":
 *             var updated_socket = socket.assign({todos: newTodos});
 *             NoReply(updated_socket);
 *         case "invalid_event":
 *             Error("Unknown event", socket);
 *         case _: 
 *             NoReply(socket);
 *     };
 * }
 * ```
 * 
 * ## Return Types
 * 
 * - **NoReply(socket)**: Update socket and continue (most common)
 * - **Reply(message, socket)**: Send reply to client and update socket
 * - **Error(reason, socket)**: Handle error with context
 * 
 * ## Type Safety Benefits
 * 
 * - **Exhaustive pattern matching**: All event cases must be handled
 * - **Socket consistency**: Input and output socket types must match
 * - **Compile-time validation**: Invalid socket operations caught early
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:no_reply, term()} |
    {:reply, term(), term()} |
    {:error, term(), term()}

  @doc """
  Creates no_reply enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec no_reply(term()) :: {:no_reply, term()}
  def no_reply(arg0) do
    {:no_reply, arg0}
  end

  @doc """
  Creates reply enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec reply(term(), term()) :: {:reply, term(), term()}
  def reply(arg0, arg1) do
    {:reply, arg0, arg1}
  end

  @doc """
  Creates error enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec error(term(), term()) :: {:error, term(), term()}
  def error(arg0, arg1) do
    {:error, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is no_reply variant"
  @spec is_no_reply(t()) :: boolean()
  def is_no_reply({:no_reply, _}), do: true
  def is_no_reply(_), do: false

  @doc "Returns true if value is reply variant"
  @spec is_reply(t()) :: boolean()
  def is_reply({:reply, _}), do: true
  def is_reply(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error({:error, _}), do: true
  def is_error(_), do: false

  @doc "Extracts value from no_reply variant, returns {:ok, value} or :error"
  @spec get_no_reply_value(t()) :: {:ok, term()} | :error
  def get_no_reply_value({:no_reply, value}), do: {:ok, value}
  def get_no_reply_value(_), do: :error

  @doc "Extracts value from reply variant, returns {:ok, value} or :error"
  @spec get_reply_value(t()) :: {:ok, {term(), term()}} | :error
  def get_reply_value({:reply, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_reply_value(_), do: :error

  @doc "Extracts value from error variant, returns {:ok, value} or :error"
  @spec get_error_value(t()) :: {:ok, {term(), term()}} | :error
  def get_error_value({:error, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_error_value(_), do: :error

end


defmodule HandleInfoResult do
  @moduledoc """
  HandleInfoResult enum generated from Haxe
  
  
 * Info message handling return type with full type safety  
 * 
 * @param TAssigns The application-specific socket assigns structure type
 * 
 * ## Generic Usage Pattern
 * 
 * ```haxe
 * public static function handle_info(info: PubSubMessage, socket: Socket<MyAssigns>): HandleInfoResult<MyAssigns> {
 *     return switch (parseMessage(info)) {
 *         case Some(TodoCreated(todo)):
 *             var updated_todos = [todo].concat(socket.assigns.todos);
 *             var updated_socket = socket.assign({todos: updated_todos});
 *             NoReply(updated_socket);
 *         case Some(SystemAlert(message)):
 *             var updated_socket = socket.put_flash("info", message);
 *             NoReply(updated_socket);
 *         case None:
 *             // Unknown message - log and ignore
 *             NoReply(socket);
 *     };
 * }
 * ```
 * 
 * ## Return Types
 * 
 * - **NoReply(socket)**: Update socket and continue (most common)
 * - **Error(reason, socket)**: Handle error with context
 * 
 * ## Type Safety Benefits
 * 
 * - **Message type safety**: Combined with type-safe PubSub for end-to-end safety
 * - **Socket consistency**: Input and output socket types must match  
 * - **Real-time validation**: PubSub message parsing errors caught at compile time
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:no_reply, term()} |
    {:error, term(), term()}

  @doc """
  Creates no_reply enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec no_reply(term()) :: {:no_reply, term()}
  def no_reply(arg0) do
    {:no_reply, arg0}
  end

  @doc """
  Creates error enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec error(term(), term()) :: {:error, term(), term()}
  def error(arg0, arg1) do
    {:error, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is no_reply variant"
  @spec is_no_reply(t()) :: boolean()
  def is_no_reply({:no_reply, _}), do: true
  def is_no_reply(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error({:error, _}), do: true
  def is_error(_), do: false

  @doc "Extracts value from no_reply variant, returns {:ok, value} or :error"
  @spec get_no_reply_value(t()) :: {:ok, term()} | :error
  def get_no_reply_value({:no_reply, value}), do: {:ok, value}
  def get_no_reply_value(_), do: :error

  @doc "Extracts value from error variant, returns {:ok, value} or :error"
  @spec get_error_value(t()) :: {:ok, {term(), term()}} | :error
  def get_error_value({:error, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_error_value(_), do: :error

end
