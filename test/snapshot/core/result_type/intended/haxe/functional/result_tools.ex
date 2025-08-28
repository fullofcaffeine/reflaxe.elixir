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
  @doc "Generated from Haxe map"
  def map(result, transform) do
    temp_result = nil

    temp_result = nil

    case result do
      0 -> value = elem(result, 1)
    temp_result = {:ok, transform.(value)}
      1 -> error = elem(result, 1)
    temp_result = {:error, error}
    end

    temp_result
  end

  @doc "Generated from Haxe flatMap"
  def flat_map(result, transform) do
    temp_result = nil

    case result do
      0 -> value = elem(result, 1)
    temp_result = transform.(value)
      1 -> error = elem(result, 1)
    temp_result = {:error, error}
    end

    temp_result
  end

  @doc "Generated from Haxe bind"
  def bind(result, transform) do
    ResultTools.flat_map(result, transform)
  end

  @doc "Generated from Haxe fold"
  def fold(result, on_success, on_error) do
    temp_result = nil

    case result do
      0 -> value = elem(result, 1)
    temp_result = on_success.(value)
      1 -> error = elem(result, 1)
    temp_result = on_error.(error)
    end

    temp_result
  end

  @doc "Generated from Haxe isOk"
  def is_ok(result) do
    temp_result = nil

    case result do
      0 -> g_param_0 = elem(result, 1)
    temp_result = true
      1 -> g_param_0 = elem(result, 1)
    temp_result = false
    end

    temp_result
  end

  @doc "Generated from Haxe isError"
  def is_error(result) do
    temp_result = nil

    case result do
      0 -> g_param_0 = elem(result, 1)
    temp_result = false
      1 -> g_param_0 = elem(result, 1)
    temp_result = true
    end

    temp_result
  end

  @doc "Generated from Haxe unwrap"
  def unwrap(result) do
    temp_result = nil

    case result do
      0 -> value = elem(result, 1)
    temp_result = value
      1 -> error = elem(result, 1)
    raise "Attempted to unwrap Error result: " <> Std.string(error)
    end

    temp_result
  end

  @doc "Generated from Haxe unwrapOr"
  def unwrap_or(result, default_value) do
    temp_result = nil

    case result do
      0 -> value = elem(result, 1)
    temp_result = value
      1 -> g_param_0 = elem(result, 1)
    temp_result = default_value
    end

    temp_result
  end

  @doc "Generated from Haxe unwrapOrElse"
  def unwrap_or_else(result, error_handler) do
    temp_result = nil

    case result do
      0 -> value = elem(result, 1)
    temp_result = value
      1 -> error = elem(result, 1)
    temp_result = error_handler.(error)
    end

    temp_result
  end

  @doc "Generated from Haxe filter"
  def filter(result, predicate, error_value) do
    temp_result = nil

    case result do
      0 -> value = elem(result, 1)
    if predicate.(value), do: temp_result = {:ok, value}, else: temp_result = {:error, error_value}
      1 -> error = elem(result, 1)
    temp_result = {:error, error}
    end

    temp_result
  end

  @doc "Generated from Haxe mapError"
  def map_error(result, transform) do
    temp_result = nil

    case result do
      0 -> value = elem(result, 1)
    temp_result = {:ok, value}
      1 -> error = elem(result, 1)
    temp_result = {:error, transform.(error)}
    end

    temp_result
  end

  @doc "Generated from Haxe bimap"
  def bimap(result, on_success, on_error) do
    temp_result = nil

    case result do
      0 -> value = elem(result, 1)
    temp_result = {:ok, on_success.(value)}
      1 -> error = elem(result, 1)
    temp_result = {:error, on_error.(error)}
    end

    temp_result
  end

  @doc "Generated from Haxe ok"
  def ok(value) do
    {:ok, value}
  end

  @doc "Generated from Haxe error"
  def error(error) do
    {:error, error}
  end

  @doc "Generated from Haxe sequence"
  def sequence(results) do
    values = []

    g_counter = 0

    (fn loop ->
      if ((g_counter < results.length)) do
            result = Enum.at(results, g_counter)
        g_counter + 1
        case result do
          0 -> value = elem(result, 1)
        values = values ++ [value]
          1 -> error = elem(result, 1)
        {:error, error}
        end
        loop.()
      end
    end).()

    {:ok, values}
  end

  @doc "Generated from Haxe traverse"
  def traverse(array, transform) do
    g_array = []

    g_counter = 0

    (fn loop ->
      if ((g_counter < array.length)) do
            v = Enum.at(array, g_counter)
        g_counter + 1
        g_array = g_array ++ [transform.(v)]
        loop.()
      end
    end).()

    ResultTools.sequence(g_array)
  end

  @doc "Generated from Haxe toOption"
  def to_option(result) do
    temp_result = nil

    case result do
      0 -> value = elem(result, 1)
    temp_result = Option.some(value)
      1 -> g_param_0 = elem(result, 1)
    temp_result = :error
    end

    temp_result
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
