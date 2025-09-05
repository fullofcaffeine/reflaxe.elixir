defmodule ResultTools do
  def map(result, transform) do
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        value = g
        {:Ok, transform.(value)}
      1 ->
        g = elem(result, 1)
        error = g
        {:Error, error}
    end
  end
  def flat_map(result, transform) do
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        value = g
        {:ModuleRef, value}
      1 ->
        g = elem(result, 1)
        error = g
        {:Error, error}
    end
  end
  def fold(result, on_success, on_error) do
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        value = g
        on_success.(value)
      1 ->
        g = elem(result, 1)
        error = g
        on_error.(error)
    end
  end
  def is_ok(result) do
    case (elem(result, 0)) do
      0 ->
        _g = elem(result, 1)
        true
      1 ->
        _g = elem(result, 1)
        false
    end
  end
  def is_error(result) do
    case (elem(result, 0)) do
      0 ->
        _g = elem(result, 1)
        false
      1 ->
        _g = elem(result, 1)
        true
    end
  end
  def unwrap(result) do
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        value = g
        value
      1 ->
        g = elem(result, 1)
        error = g
        throw("Attempted to unwrap Error result: " <> Std.string(error))
    end
  end
  def unwrap_or(result, default_value) do
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        value = g
        value
      1 ->
        _g = elem(result, 1)
        default_value
    end
  end
  def unwrap_or_else(result, error_handler) do
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        value = g
        value
      1 ->
        g = elem(result, 1)
        error = g
        error_handler.(error)
    end
  end
  def filter(result, predicate, error_value) do
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        value = g
        if (predicate.(value)), do: {:Ok, value}, else: {:Error, error_value}
      1 ->
        g = elem(result, 1)
        error = g
        {:Error, error}
    end
  end
  def map_error(result, transform) do
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        value = g
        {:Ok, value}
      1 ->
        g = elem(result, 1)
        error = g
        {:Error, transform.(error)}
    end
  end
  def bimap(result, on_success, on_error) do
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        value = g
        {:Ok, on_success.(value)}
      1 ->
        g = elem(result, 1)
        error = g
        {:Error, on_error.(error)}
    end
  end
  def sequence(results) do
    values = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, results, :ok}, fn _, {acc_g, acc_results, acc_state} ->
  if (acc_g < acc_results.length) do
    result = results[g]
    acc_g = acc_g + 1
    case (elem(result, 0)) do
      0 ->
        acc_g = elem(result, 1)
        value = acc_g
        values ++ [value]
      1 ->
        acc_g = elem(result, 1)
        error = acc_g
        {:Error, error}
    end
    {:cont, {acc_g, acc_results, acc_state}}
  else
    {:halt, {acc_g, acc_results, acc_state}}
  end
end)
    {:Ok, values}
  end
  def traverse(array, transform) do
    results = Enum.map(array, transform)
    {:Sequence, results}
  end
  def to_option(result) do
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        value = g
        {:Some, value}
      1 ->
        _g = elem(result, 1)
        :none
    end
  end
end