defmodule ResultTools do
  def map(result, transform) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        {:Ok, transform.(value)}
      1 ->
        g = result.elem(1)
        error = g
        {:Error, error}
    end
  end
  def flat_map(result, transform) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        {:ModuleRef, value}
      1 ->
        g = result.elem(1)
        error = g
        {:Error, error}
    end
  end
  def bind(result, transform) do
    {:FlatMap, result, transform}
  end
  def fold(result, on_success, on_error) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        on_success.(value)
      1 ->
        g = result.elem(1)
        error = g
        on_error.(error)
    end
  end
  def is_ok(result) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        true
      1 ->
        g = result.elem(1)
        false
    end
  end
  def is_error(result) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        false
      1 ->
        g = result.elem(1)
        true
    end
  end
  def unwrap(result) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        value
      1 ->
        g = result.elem(1)
        error = g
        throw("Attempted to unwrap Error result: " + Std.string(error))
    end
  end
  def unwrap_or(result, default_value) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        value
      1 ->
        g = result.elem(1)
        default_value
    end
  end
  def unwrap_or_else(result, error_handler) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        value
      1 ->
        g = result.elem(1)
        error = g
        error_handler.(error)
    end
  end
  def filter(result, predicate, error_value) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        if (predicate.(value)), do: {:Ok, value}, else: {:Error, error_value}
      1 ->
        g = result.elem(1)
        error = g
        {:Error, error}
    end
  end
  def map_error(result, transform) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        {:Ok, value}
      1 ->
        g = result.elem(1)
        error = g
        {:Error, transform.(error)}
    end
  end
  def bimap(result, on_success, on_error) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        {:Ok, on_success.(value)}
      1 ->
        g = result.elem(1)
        error = g
        {:Error, on_error.(error)}
    end
  end
  def ok(value) do
    {:Ok, value}
  end
  def error(error) do
    {:Error, error}
  end
  def sequence(results) do
    values = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < results.length) do
  result = results[g]
  g + 1
  case (result.elem(0)) do
    0 ->
      g = result.elem(1)
      value = g
      values.push(value)
    1 ->
      g = result.elem(1)
      error = g
      {:Error, error}
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    {:Ok, values}
  end
  def traverse(array, transform) do
    results = Enum.map(array, transform)
    {:Sequence, results}
  end
  def to_option(result) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        {:Some, value}
      1 ->
        g = result.elem(1)
        :None
    end
  end
end