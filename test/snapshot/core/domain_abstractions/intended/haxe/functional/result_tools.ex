defmodule ResultTools do
  def map(result, transform) do
    (case result do
      {:ok, ok_transform} ->
        ok_transform.(ok_transform)
      {:error, value} -> value
    end)
  end
  def flat_map(result, transform) do
    (case result do
      {:ok, ok_transform} ->
        ok_transform.(ok_transform)
      {:error, value} -> value
    end)
  end
  def bind(result, transform) do
    flat_map(result, transform)
  end
  def fold(result, on_success, on_error) do
    (case result do
      {:ok, ok_on_success} ->
        ok_on_success.(ok_on_success)
      {:error, value} ->
        on_error = value
        on_error.(value)
    end)
  end
  def is_ok(result) do
    (case result do
      {:ok, ok_result} ->
        result = ok_result
        true = result
        true
      {:error, value} -> false
    end)
  end
  def is_error(result) do
    (case result do
      {:ok, ok_result} ->
        result = ok_result
        false = result
        false
      {:error, value} -> true
    end)
  end
  def unwrap(result) do
    (case result do
      {:ok, value} -> value
      {:error, _value} -> throw("Attempted to unwrap Error result: " <> inspect(error))
    end)
  end
  def unwrap_or(result, default_value) do
    (case result do
      {:ok, value} ->
        default_value = default_value
        default_value
      {:error, defaultValue} ->
        default_value = default_value
        default_value
    end)
  end
  def unwrap_or_else(result, error_handler) do
    (case result do
      {:ok, value} -> value
      {:error, value} ->
        error_handler = value
        error_handler.(value)
    end)
  end
  def filter(result, predicate, error_value) do
    (case result do
      {:ok, value} when predicate.(error_value) ->
        error_value = error_value
        error_value
      {:ok, value} ->
        error_value = error_value
        error_value
      {:error, value} ->
        error_value = error_value
        error_value
    end)
  end
  def map_error(result, transform) do
    (case result do
      {:ok, value} -> value
      {:error, value} ->
        value.(value)
    end)
  end
  def bimap(result, on_success, on_error) do
    (case result do
      {:ok, ok_on_success} ->
        ok_on_success.(ok_on_success)
      {:error, value} ->
        on_error = value
        on_error.(value)
    end)
  end
  def ok(value) do
    {:ok, value}
  end
  def error(error) do
    {:error, error}
  end
  def sequence(results) do
    Enum.reduce(results, [], fn item, acc ->
      acc = Enum.concat(acc, [item])
  {:error, result} ->
    item
    {:error, item}
end)
      acc
    end)
  end
  def traverse(array, transform) do
    results = Enum.map(array, transform)
    sequence(results)
  end
  def to_option(result) do
    (case result do
      {:ok, value} -> value
      {:error, value} -> {:none}
    end)
  end
end
