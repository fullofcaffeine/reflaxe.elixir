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
