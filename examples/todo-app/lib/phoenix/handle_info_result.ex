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
