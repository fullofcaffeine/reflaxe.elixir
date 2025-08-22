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
  @doc """
    Transform the value inside Some, leaving None unchanged.

    This is the Functor map operation. In Gleam terms, it applies a function
    to the wrapped value if present, otherwise returns None.

    @param option The option to transform
    @param transform Function to apply to the contained value
    @return New option with transformed value or None
  """
  @spec map(Option.t(), Function.t()) :: Option.t()
  def map(option, transform) do
    (
          temp_result = nil
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          value = g
          temp_result = Option.some(transform.(value))
        )
      1 -> temp_result = :error
    end
          temp_result
        )
  end

  @doc """
    Apply a function that returns an Option, flattening nested Options.

    This is the Monad bind operation. Gleam calls this 'then'.
    Essential for chaining operations that may return None.

    @param option The option to transform
    @param transform Function that takes value and returns an Option
    @return Flattened result of the transformation
  """
  @spec then(Option.t(), Function.t()) :: Option.t()
  def then(option, transform) do
    (
          temp_result = nil
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          value = g
          temp_result = transform.(value)
        )
      1 -> temp_result = :error
    end
          temp_result
        )
  end

  @doc """
    Alternative name for 'then' following Haskell/Rust conventions.
    @see then
  """
  @spec flat_map(Option.t(), Function.t()) :: Option.t()
  def flat_map(option, transform) do
    OptionTools.then(option, transform)
  end

  @doc """
    Flatten nested Options into a single Option.

    Converts Option<Option<T>> to Option<T>.
    Following Gleam's flatten operation.

    @param option The nested option to flatten
    @return Flattened option
  """
  @spec flatten(Option.t()) :: Option.t()
  def flatten(option) do
    (
          temp_result = nil
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          inner = g
          temp_result = inner
        )
      1 -> temp_result = :error
    end
          temp_result
        )
  end

  @doc """
    Keep the Option only if the contained value satisfies a predicate.

    @param option The option to filter
    @param predicate Function to test the contained value
    @return Original option if predicate passes, None otherwise
  """
  @spec filter(Option.t(), Function.t()) :: Option.t()
  def filter(option, predicate) do
    (
          temp_result = nil
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          value = g
          if (predicate.(value)) do
          temp_result = Option.some(value)
        else
          temp_result = :error
        end
        )
      1 -> temp_result = :error
    end
          temp_result
        )
  end

  @doc """
    Extract the contained value or return a default.

    Following Gleam's 'unwrap' naming convention.
    Safe extraction that never crashes.

    @param option The option to unwrap
    @param defaultValue Value to return if option is None
    @return Contained value or default
  """
  @spec unwrap(Option.t(), T.t()) :: T.t()
  def unwrap(option, default_value) do
    (
          temp_result = nil
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          value = g
          temp_result = value
        )
      1 -> temp_result = default_value
    end
          temp_result
        )
  end

  @doc """
    Extract the contained value or compute a default lazily.

    Following Gleam's 'lazy_unwrap' pattern for expensive defaults.

    @param option The option to unwrap
    @param fn Function to compute default if needed
    @return Contained value or computed default
  """
  @spec lazy_unwrap(Option.t(), Function.t()) :: T.t()
  def lazy_unwrap(option, fn_) do
    (
          temp_result = nil
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          value = g
          temp_result = value
        )
      1 -> temp_result = fn_.()
    end
          temp_result
        )
  end

  @doc """
    Return the first option if it contains a value, otherwise the second.

    Following Gleam's 'or' operation for combining Options.

    @param first First option to try
    @param second Fallback option
    @return First option if Some, otherwise second option
  """
  @spec or_(Option.t(), Option.t()) :: Option.t()
  def or_(first, second) do
    (
          temp_result = nil
          case (case first do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          case first do {:ok, value} -> value; :error -> nil; _ -> nil end
          temp_result = first
        )
      1 -> temp_result = second
    end
          temp_result
        )
  end

  @doc """
    Return the first option if it contains a value, otherwise compute fallback.

    Following Gleam's 'lazy_or' pattern for expensive alternatives.

    @param first First option to try
    @param fn Function to compute alternative option
    @return First option if Some, otherwise computed alternative
  """
  @spec lazy_or(Option.t(), Function.t()) :: Option.t()
  def lazy_or(first, fn_) do
    (
          temp_result = nil
          case (case first do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          case first do {:ok, value} -> value; :error -> nil; _ -> nil end
          temp_result = first
        )
      1 -> temp_result = fn_.()
    end
          temp_result
        )
  end

  @doc """
    Check if the option contains a value.

    @param option The option to check
    @return true if Some, false if None
  """
  @spec is_some(Option.t()) :: boolean()
  def is_some(option) do
    (
          temp_result = nil
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          temp_result = true
        )
      1 -> temp_result = false
    end
          temp_result
        )
  end

  @doc """
    Check if the option is empty.

    @param option The option to check
    @return true if None, false if Some
  """
  @spec is_none(Option.t()) :: boolean()
  def is_none(option) do
    (
          temp_result = nil
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          temp_result = false
        )
      1 -> temp_result = true
    end
          temp_result
        )
  end

  @doc """
    Convert all Options in an array to an array of values.

    Following Gleam's 'all' operation. Returns Some(array) if all options
    contain values, otherwise None.

    @param options Array of options to combine
    @return Some containing array of all values, or None if any option is None
  """
  @spec all(Array.t()) :: Option.t()
  def all(options) do
    (
          values = []
          g_counter = 0
          while_loop(fn -> ((g < options.length)) end, fn -> (
          option = Enum.at(options, g)
          g + 1
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          value = g
          &OptionTools.values/1 ++ [value]
        )
      1 -> :error
    end
        ) end)
          Option.some(&OptionTools.values/1)
        )
  end

  @doc """
    Extract all Some values from an array of Options, discarding None values.

    Following Gleam's 'values' operation. Always succeeds, returning
    an array containing only the unwrapped Some values.

    @param options Array of options to extract values from
    @return Array containing all unwrapped Some values
  """
  @spec values(Array.t()) :: Array.t()
  def values(options) do
    (
          result = []
          g_counter = 0
          while_loop(fn -> ((g < options.length)) end, fn -> (
          option = Enum.at(options, g)
          g + 1
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          value = g
          result ++ [value]
        )
      1 -> nil
    end
        ) end)
          result
        )
  end

  @doc """
    Convert Option to Result for error handling chains.

    Essential for OTP patterns where absence is an error condition.
    Enables chaining with other Result-returning functions.

    @param option The option to convert
    @param error Error value to use if option is None
    @return Ok with contained value, or Error with provided error
  """
  @spec to_result(Option.t(), E.t()) :: Result.t()
  def to_result(option, error) do
    (
          temp_result = nil
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          value = g
          temp_result = {:ok, value}
        )
      1 -> temp_result = {:error, error}
    end
          temp_result
        )
  end

  @doc """
    Convert Result to Option, discarding error information.

    Useful when you only care about success/failure, not the specific error.

    @param result The result to convert
    @return Some with success value, or None for any error
  """
  @spec from_result(Result.t()) :: Option.t()
  def from_result(result) do
    (
          temp_result = nil
          case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> (
          g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          value = g
          temp_result = Option.some(value)
        )
      1 -> (
          case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          temp_result = :error
        )
    end
          temp_result
        )
  end

  @doc """
    Convert nullable value to Option.

    Bridge between Haxe's nullable types and type-safe Option handling.

    @param value Nullable value to convert
    @return Some(value) if not null, None if null
  """
  @spec from_nullable(Null.t()) :: Option.t()
  def from_nullable(value) do
    (
          temp_result = nil
          if ((value != nil)) do
          temp_result = Option.some(value)
        else
          temp_result = :error
        end
          temp_result
        )
  end

  @doc """
    Convert Option to nullable value.

    For interop with APIs that expect nullable types.
    Use sparingly - prefer Option for type safety.

    @param option The option to convert
    @return Contained value or null
  """
  @spec to_nullable(Option.t()) :: Null.t()
  def to_nullable(option) do
    (
          temp_result = nil
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          value = g
          temp_result = value
        )
      1 -> temp_result = nil
    end
          temp_result
        )
  end

  @doc """
    Convert Option to OTP-style reply tuple.

    For GenServer handle_call implementations. Generates appropriate
    {:reply, response, state} patterns.

    @param option The option to convert to reply
    @return Dynamic tuple appropriate for GenServer replies
  """
  @spec to_reply(Option.t()) :: term()
  def to_reply(option) do
    (
          temp_result = nil
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          value = g
          temp_result = %{"reply" => value, "status" => "ok"}
        )
      1 -> temp_result = %{"reply" => nil, "status" => "none"}
    end
          temp_result
        )
  end

  @doc """
    Extract value with clear crash message if None.

    Following Gleam's philosophy: crash fast with helpful error messages.
    Use only when None indicates a programming error.

    @param option The option to extract from
    @param message Error message for the crash
    @return The contained value (never returns if None)
    @throws String if option is None
  """
  @spec expect(Option.t(), String.t()) :: T.t()
  def expect(option, message) do
    (
          temp_result = nil
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          value = g
          temp_result = value
        )
      1 -> raise "Expected Some value but got None: " <> message
    end
          temp_result
        )
  end

  @doc """
    Convenience constructor for Some values.

    @param value The value to wrap
    @return Some containing the value
  """
  @spec some(T.t()) :: Option.t()
  def some(value) do
    Option.some(value)
  end

  @doc """
    Convenience constructor for None values.

    @return None option
  """
  @spec none() :: Option.t()
  def none() do
    :error
  end

  @doc """
    Apply a side-effect function to the contained value if present.

    Useful for performing actions on Some values without changing the Option.

    @param option The option to apply the function to
    @param fn Function to apply for side effects
    @return The original option unchanged
  """
  @spec apply(Option.t(), Function.t()) :: Option.t()
  def apply(option, fn_) do
    (
          case (case option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case option do {:ok, value} -> value; :error -> nil; _ -> nil end
          value = g
          fn_.(value)
        )
      1 -> nil
    end
          option
        )
  end

end
