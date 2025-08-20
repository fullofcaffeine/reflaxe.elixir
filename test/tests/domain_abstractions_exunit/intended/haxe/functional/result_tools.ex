defmodule ResultTools do
  @moduledoc """
    ResultTools module generated from Haxe

     * Companion class providing functional operations for Result<T,E>
     *
     * Implements the full functional toolkit for Result types:
     * - Functor operations (map)
     * - Monad operations (flatMap/bind)
     * - Foldable operations (fold)
     * - Utility functions (isOk, isError, unwrap)
     *
     * All operations are designed to work seamlessly across all Haxe targets
     * while generating optimal target-specific code.
  """

  # Static functions
  @doc """
    Apply a function to the success value, leaving errors unchanged.

    This is the Functor map operation for Result types.

    @param result The result to transform
    @param transform Function to apply to success values
    @return New result with transformed success value or unchanged error
  """
  @spec map(Result.t(), Function.t()) :: Result.t()
  def map(result, transform) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        value = g
        temp_result = {:ok, transform.(value)}
      1 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        error = g
        temp_result = {:error, &ResultTools.error/1}
    end
    temp_result
  end

  @doc """
    Apply a function that returns a Result, flattening nested Results.

    This is the Monad bind/flatMap operation for Result types.
    Essential for chaining operations that can fail.

    @param result The result to transform
    @param transform Function that takes success value and returns a Result
    @return Flattened result of the transformation
  """
  @spec flat_map(Result.t(), Function.t()) :: Result.t()
  def flat_map(result, transform) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        value = g
        temp_result = transform.(value)
      1 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        error = g
        temp_result = {:error, &ResultTools.error/1}
    end
    temp_result
  end

  @doc """
    Alternative name for flatMap following Haskell/Rust conventions.
    @see flatMap
  """
  @spec bind(Result.t(), Function.t()) :: Result.t()
  def bind(result, transform) do
    ResultTools.flat_map(result, &ResultTools.transform/1)
  end

  @doc """
    Extract a value from Result by providing handlers for both cases.

    This is the canonical way to consume a Result value.
    Ensures exhaustive handling of both success and error cases.

    @param result The result to fold
    @param onSuccess Function to handle success values
    @param onError Function to handle error values
    @return The result of applying the appropriate handler
  """
  @spec fold(Result.t(), Function.t(), Function.t()) :: R.t()
  def fold(result, on_success, on_error) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        value = g
        temp_result = on_success.(value)
      1 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        error = g
        temp_result = on_error.(&ResultTools.error/1)
    end
    temp_result
  end

  @doc """
    Check if result represents a successful value.
    @param result The result to check
    @return true if result is Ok, false if Error
  """
  @spec is_ok(Result.t()) :: boolean()
  def is_ok(result) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        temp_result = true
      1 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        temp_result = false
    end
    temp_result
  end

  @doc """
    Check if result represents an error.
    @param result The result to check
    @return true if result is Error, false if Ok
  """
  @spec is_error(Result.t()) :: boolean()
  def is_error(result) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        temp_result = false
      1 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        temp_result = true
    end
    temp_result
  end

  @doc """
    Extract the success value, throwing an exception if it's an error.

    Use with caution - prefer pattern matching or fold for safe extraction.

    @param result The result to unwrap
    @return The success value
    @throws String if result is an Error
  """
  @spec unwrap(Result.t()) :: T.t()
  def unwrap(result) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        value = g
        temp_result = value
      1 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        error = g
        throw("Attempted to unwrap Error result: " <> Std.string(&ResultTools.error/1))
    end
    temp_result
  end

  @doc """
    Extract the success value or return a default.

    Safe alternative to unwrap that never throws.

    @param result The result to unwrap
    @param defaultValue Value to return if result is Error
    @return Success value or default
  """
  @spec unwrap_or(Result.t(), T.t()) :: T.t()
  def unwrap_or(result, default_value) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        value = g
        temp_result = value
      1 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        temp_result = default_value
    end
    temp_result
  end

  @doc """
    Extract the success value or compute a default from the error.

    @param result The result to unwrap
    @param errorHandler Function to compute default from error
    @return Success value or computed default
  """
  @spec unwrap_or_else(Result.t(), Function.t()) :: T.t()
  def unwrap_or_else(result, error_handler) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        value = g
        temp_result = value
      1 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        error = g
        temp_result = error_handler.(&ResultTools.error/1)
    end
    temp_result
  end

  @doc """
    Filter the success value with a predicate, converting to error if predicate fails.

    @param result The result to filter
    @param predicate Function to test the success value
    @param errorValue Error to return if predicate fails
    @return Original result if predicate passes, error otherwise
  """
  @spec filter(Result.t(), Function.t(), E.t()) :: Result.t()
  def filter(result, predicate, error_value) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        value = g
        temp_result = if (predicate.(value)), do: {:ok, value}, else: {:error, error_value}
      1 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        error = g
        temp_result = {:error, &ResultTools.error/1}
    end
    temp_result
  end

  @doc """
    Transform the error type, leaving success values unchanged.

    @param result The result to transform
    @param transform Function to apply to error values
    @return Result with transformed error type
  """
  @spec map_error(Result.t(), Function.t()) :: Result.t()
  def map_error(result, transform) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        value = g
        temp_result = {:ok, value}
      1 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        error = g
        temp_result = {:error, transform.(&ResultTools.error/1)}
    end
    temp_result
  end

  @doc """
    Apply a Result-returning function to both success and error cases.

    This allows converting between different Result types entirely.

    @param result The result to transform
    @param onSuccess Function to transform success values
    @param onError Function to transform error values
    @return New result from appropriate transformation
  """
  @spec bimap(Result.t(), Function.t(), Function.t()) :: Result.t()
  def bimap(result, on_success, on_error) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        value = g
        temp_result = {:ok, on_success.(value)}
      1 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        error = g
        temp_result = {:error, on_error.(&ResultTools.error/1)}
    end
    temp_result
  end

  @doc """
    Create a successful Result.

    Convenience constructor function.

    @param value The success value
    @return Ok Result containing the value
  """
  @spec ok(T.t()) :: Result.t()
  def ok(value) do
    {:ok, value}
  end

  @doc """
    Create an error Result.

    Convenience constructor function.

    @param error The error value
    @return Error Result containing the error
  """
  @spec error(E.t()) :: Result.t()
  def error(error) do
    {:error, &ResultTools.error/1}
  end

  @doc """
    Convert an Array of Results into a Result of Array.

    Returns Ok with all values if all Results are Ok,
    or the first Error encountered.

    @param results Array of Results to sequence
    @return Result containing array of all values or first error
  """
  @spec sequence(Array.t()) :: Result.t()
  def sequence(results) do
    values = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < results.length) do
          try do
            result = Enum.at(results, g)
          g = g + 1
          case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        value = g
        values ++ [value]
      1 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        error = g
        {:error, &ResultTools.error/1}
    end
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    {:ok, values}
  end

  @doc """
    Apply a function to an array, collecting successful Results.

    Like Array.map but collects all Results into a single Result.
    Fails fast on the first error encountered.

    @param array Array of input values
    @param transform Function that may fail
    @return Result containing array of all successes or first error
  """
  @spec traverse(Array.t(), Function.t()) :: Result.t()
  def traverse(array, transform) do
    _g_array = []
    _g_counter = 0
    (
      loop_helper = fn loop_fn, {g_counter} ->
        if (g < array.length) do
          try do
            v = Enum.at(array, g)
    g = g + 1
    _g_counter.push(&ResultTools.transform/1(v))
            loop_fn.(loop_fn, {g_counter})
          catch
            :break -> {g_counter}
            :continue -> loop_fn.(loop_fn, {g_counter})
          end
        else
          {g_counter}
        end
      end
      {g_counter} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    ResultTools.sequence(g)
  end

  @doc """
    Convert Result to Option, discarding error information.

    Useful when you only care about success/failure, not the specific error.

    @param result The result to convert
    @return Some with success value, or None for any error
  """
  @spec to_option(Result.t()) :: Option.t()
  def to_option(result) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        value = g
        temp_result = {:ok, value}
      1 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        temp_result = :error
    end
    temp_result
  end

end
