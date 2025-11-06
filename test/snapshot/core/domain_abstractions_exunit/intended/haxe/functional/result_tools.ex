defmodule ResultTools do
  def map(result, transform) do
    (case result do
      {:ok, value} ->
        value.(value)
      {:error, value} -> value
    end)
  end
  def flat_map(result, transform) do
    (case result do
      {:ok, value} ->
        value.(value)
      {:error, value} -> value
    end)
  end
  def bind(result, transform) do
    flat_map(result, transform)
  end
  def fold(result, on_success, on_error) do
    (case result do
      {:ok, value} ->
        value.(value)
      {:error, on_error} ->
        on_error.(on_error)
    end)
  end
  def is_ok(result) do
    (case result do
      {:ok, value} ->
        true = value
        true
      {:error, value} -> false
    end)
  end
  def is_error(result) do
    (case result do
      {:ok, value} ->
        false = value
        false
      {:error, value} -> true
    end)
  end
  def unwrap(result) do
    (case result do
      {:ok, value} ->
        _ = value
        value
      {:error, _value} -> throw("Attempted to unwrap Error result: " <> inspect(error))
    end)
  end
  def unwrap_or(result, default_value) do
    (case result do
      {:ok, value} ->
        default_value = value
        default_value
      {:error, default_value} ->
        default_value = default_value
        default_value
    end)
  end
  def unwrap_or_else(result, error_handler) do
    (case result do
      {:ok, value} -> value
      {:error, error_handler} ->
        error_handler.(error_handler)
    end)
  end
  def filter(result, predicate, error_value) do
    (case result do
      {:ok, value} when predicate.(error_value) ->
        error_value = value
        error_value
      {:ok, value} ->
        error_value = value
        error_value
      {:error, value} -> error_value
    end)
  end
  def map_error(result, transform) do
    (case result do
      {:ok, value} -> value
      {:error, transform} ->
        transform.(transform)
    end)
  end
  def bimap(result, on_success, on_error) do
    (case result do
      {:ok, value} ->
        value.(value)
      {:error, on_error} ->
        on_error.(on_error)
    end)
  end
  def ok(value) do
    {:ok, value}
  end
  def error(error) do
    {:error, error}
  end
  def sequence(results) do
    values = []
    _ = Enum.each(results, (fn -> fn item ->
    (case item do
    {:ok, values} ->
      item = Enum.concat(item, [item])
    {:error, reason} ->
      error = reason
      {:error, error}
  end)
end end).())
    {:ok, values}
  end
  def traverse(array, transform) do
    results = Enum.map(array, transform)
    _ = sequence(results)
    _
  end
  def to_option(result) do
    (case result do
      {:ok, value} -> value
      {:error, value} -> {:none}
    end)
  end
end
