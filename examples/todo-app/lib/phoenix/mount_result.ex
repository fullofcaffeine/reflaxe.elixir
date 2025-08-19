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
