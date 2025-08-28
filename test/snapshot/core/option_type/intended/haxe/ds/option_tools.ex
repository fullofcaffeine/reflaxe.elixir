defmodule OptionTools do
  @moduledoc """
    OptionTools module generated from Haxe

     * Functional operations for Option<T> types with BEAM-first design.
     *
     * Inspired by Gleam's approach: complete type safety, functional composition,
     * and seamless integration with OTP/BEAM patterns.
     *
     * ## Design Philosophy
     *
     * All operations follow Gleam's naming conventions and functional programming
     * principles while compiling to idiomatic BEAM code:
     *
     * - **Functor operations**: map for transforming contained values
     * - **Monad operations**: then (flatMap) for chaining Option-returning functions
     * - **Collection operations**: all, values for working with arrays
     * - **BEAM integration**: toResult, toReply for OTP patterns
     *
     * ## Usage Examples
     *
     * ```haxe
     * // Gleam-style chaining
     * var result = findUser(id)
     *     .map(user -> user.email)
     *     .filter(email -> email.contains("@"))
     *     .unwrap("unknown@example.com");
     *
     * // OTP GenServer integration
     * var reply = getUser(id).toReply();  // {:reply, {:ok, user}, state}
     *
     * // Error handling chains
     * var outcome = findUser(id)
     *     .toResult("User not found")
     *     .then(user -> updateUser(user, data));
     * ```
  """

  # Static functions
  @doc "Generated from Haxe map"
  def map(option, transform) do
    temp_result = nil

    temp_result = nil

    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(option, 1)
    temp_result = Option.some(transform.(value))
      1 -> temp_result = :error
    end

    temp_result
  end

  @doc "Generated from Haxe then"
  def then(option, transform) do
    temp_result = nil

    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(option, 1)
    temp_result = transform.(value)
      1 -> temp_result = :error
    end

    temp_result
  end

  @doc "Generated from Haxe flatMap"
  def flat_map(option, transform) do
    OptionTools.then(option, transform)
  end

  @doc "Generated from Haxe flatten"
  def flatten(option) do
    temp_result = nil

    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, inner} -> g_array = elem(option, 1)
    temp_result = inner
      1 -> temp_result = :error
    end

    temp_result
  end

  @doc "Generated from Haxe filter"
  def filter(option, predicate) do
    temp_result = nil

    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(option, 1)
    if predicate.(value), do: temp_result = Option.some(value), else: temp_result = :error
      1 -> temp_result = :error
    end

    temp_result
  end

  @doc "Generated from Haxe unwrap"
  def unwrap(option, default_value) do
    temp_result = nil

    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(option, 1)
    temp_result = value
      1 -> temp_result = default_value
    end

    temp_result
  end

  @doc "Generated from Haxe lazyUnwrap"
  def lazy_unwrap(option, fn_) do
    temp_result = nil

    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(option, 1)
    temp_result = value
      1 -> temp_result = fn_.()
    end

    temp_result
  end

  @doc "Generated from Haxe or"
  def or_(first, second) do
    temp_result = nil

    case (case first do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> temp_result = first
      1 -> temp_result = second
    end

    temp_result
  end

  @doc "Generated from Haxe lazyOr"
  def lazy_or(first, fn_) do
    temp_result = nil

    case (case first do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> temp_result = first
      1 -> temp_result = fn_.()
    end

    temp_result
  end

  @doc "Generated from Haxe isSome"
  def is_some(option) do
    temp_result = nil

    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> temp_result = true
      1 -> temp_result = false
    end

    temp_result
  end

  @doc "Generated from Haxe isNone"
  def is_none(option) do
    temp_result = nil

    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> temp_result = false
      1 -> temp_result = true
    end

    temp_result
  end

  @doc "Generated from Haxe all"
  def all(options) do
    values = []

    g_counter = 0

    Enum.each(g_array, fn option -> 
      case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(option, 1)
    values ++ [value]
      1 -> :error
    end
    end)

    Option.some(values)
  end

  @doc "Generated from Haxe values"
  def values(options) do
    result = []

    g_counter = 0

    Enum.each(g_array, fn option -> 
      case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(option, 1)
    result ++ [value]
      1 -> nil
    end
    end)

    result
  end

  @doc "Generated from Haxe toResult"
  def to_result(option, error) do
    temp_result = nil

    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(option, 1)
    temp_result = {:ok, value}
      1 -> temp_result = {:error, error}
    end

    temp_result
  end

  @doc "Generated from Haxe fromResult"
  def from_result(result) do
    temp_result = nil

    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(result, 1)
    temp_result = Option.some(value)
      1 -> temp_result = :error
    end

    temp_result
  end

  @doc "Generated from Haxe fromNullable"
  def from_nullable(value) do
    temp_result = nil

    if ((value != nil)), do: temp_result = Option.some(value), else: temp_result = :error

    temp_result
  end

  @doc "Generated from Haxe toNullable"
  def to_nullable(option) do
    temp_result = nil

    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(option, 1)
    temp_result = value
      1 -> temp_result = nil
    end

    temp_result
  end

  @doc "Generated from Haxe toReply"
  def to_reply(option) do
    temp_result = nil

    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(option, 1)
    temp_result = %{"reply" => value, "status" => "ok"}
      1 -> temp_result = %{"reply" => nil, "status" => "none"}
    end

    temp_result
  end

  @doc "Generated from Haxe expect"
  def expect(option, message) do
    temp_result = nil

    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(option, 1)
    temp_result = value
      1 -> raise "Expected Some value but got None: " <> message
    end

    temp_result
  end

  @doc "Generated from Haxe some"
  def some(value) do
    Option.some(value)
  end

  @doc "Generated from Haxe none"
  def none() do
    :error
  end

  @doc "Generated from Haxe apply"
  def apply(option, fn_) do
    case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(option, 1)
    fn_.(value)
      1 -> nil
    end

    option
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
