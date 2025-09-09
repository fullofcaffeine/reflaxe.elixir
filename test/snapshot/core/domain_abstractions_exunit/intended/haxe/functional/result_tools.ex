defmodule ResultTools do
  def map(_result, transform) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        value = g
        transform.(value)
      {:error, _} ->
        g = elem(_result, 1)
        error = g
        error
    end
  end
  def flat_map(_result, transform) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        value = g
        transform.(value)
      {:error, _} ->
        g = elem(_result, 1)
        error = g
        error
    end
  end
  def bind(result, transform) do
    flat_map(result, transform)
  end
  def fold(_result, on_success, on_error) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        value = g
        on_success.(value)
      {:error, _} ->
        g = elem(_result, 1)
        error = g
        on_error.(error)
    end
  end
  def is_ok(_result) do
    case (_result) do
      {:ok, _} ->
        _g = elem(_result, 1)
        true
      {:error, _} ->
        _g = elem(_result, 1)
        false
    end
  end
  def is_error(_result) do
    case (_result) do
      {:ok, _} ->
        _g = elem(_result, 1)
        false
      {:error, _} ->
        _g = elem(_result, 1)
        true
    end
  end
  def unwrap(_result) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        value = g
        value
      {:error, _} ->
        g = elem(_result, 1)
        error = g
        throw("Attempted to unwrap Error result: " <> Std.string(error))
    end
  end
  def unwrap_or(_result, default_value) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        value = g
        value
      {:error, _} ->
        _g = elem(_result, 1)
        default_value
    end
  end
  def unwrap_or_else(_result, error_handler) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        value = g
        value
      {:error, _} ->
        g = elem(_result, 1)
        error = g
        error_handler.(error)
    end
  end
  def filter(_result, predicate, error_value) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        value = g
        if (predicate.(value)), do: value, else: error_value
      {:error, _} ->
        g = elem(_result, 1)
        error = g
        error
    end
  end
  def map_error(_result, transform) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        value = g
        value
      {:error, _} ->
        g = elem(_result, 1)
        error = g
        transform.(error)
    end
  end
  def bimap(_result, on_success, on_error) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        value = g
        on_success.(value)
      {:error, _} ->
        g = elem(_result, 1)
        error = g
        on_error.(error)
    end
  end
  def ok(value) do
    {:ok, value}
  end
  def error(error) do
    {:error, error}
  end
  def sequence(results) do
    values = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {results, g, :ok}, fn _, {acc_results, acc_g, acc_state} ->
  if (acc_g < length(acc_results)) do
    result = results[g]
    acc_g = acc_g + 1
    nil
    {:cont, {acc_results, acc_g, acc_state}}
  else
    {:halt, {acc_results, acc_g, acc_state}}
  end
end)
    {:ok, values}
  end
  def traverse(array, transform) do
    results = Enum.map(array, transform)
    sequence(results)
  end
  def to_option(_result) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        value = g
        value
      {:error, _} ->
        _g = elem(_result, 1)
        :none
    end
  end
end