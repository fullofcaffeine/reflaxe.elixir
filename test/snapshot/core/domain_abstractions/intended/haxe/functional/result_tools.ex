defmodule ResultTools do
  def map(result, transform) do
    (case result do
      {:ok, value} ->
        _ok = value
        {:ok, value.(value)}
      {:error, reason} -> {:error, reason}
    end)
  end
  def flat_map(result, transform) do
    (case result do
      {:ok, value} ->
        value.(value)
      {:error, reason} -> {:error, reason}
    end)
  end
  def bind(result, transform) do
    flat_map(result, transform)
  end
  def fold(result, on_success, on_error) do
    (case result do
      {:ok, value} ->
        value.(value)
      {:error, reason} ->
        reason.(reason)
    end)
  end
  def is_ok(result) do
    (case result do
      {:ok, value} ->
        _true = value
        true
      {:error, __reason} -> false
    end)
  end
  def is_error(result) do
    (case result do
      {:ok, value} ->
        _false = value
        false
      {:error, __reason} -> true
    end)
  end
  def unwrap(result) do
    (case result do
      {:ok, value} -> value
      {:error, __reason} -> throw("Attempted to unwrap Error result: " <> inspect(error))
    end)
  end
  def unwrap_or(result, default_value) do
    (case result do
      {:ok, value} ->
        default_value = value
        default_value
      {:error, reason} -> reason
    end)
  end
  def unwrap_or_else(result, error_handler) do
    (case result do
      {:ok, value} -> value
      {:error, reason} ->
        reason.(reason)
    end)
  end
  def filter(result, predicate, error_value) do
    (case result do
      {:ok, errorvalue} ->
        if (errorvalue.(errorvalue)), do: {:ok, errorvalue}, else: {:error, errorvalue}
      {:error, reason} -> {:error, reason}
    end)
  end
  def map_error(result, transform) do
    (case result do
      {:ok, value} ->
        _ok = value
        {:ok, value}
      {:error, reason} -> {:error, reason.(reason)}
    end)
  end
  def bimap(result, on_success, on_error) do
    (case result do
      {:ok, value} ->
        _ok = value
        {:ok, value.(value)}
      {:error, reason} -> {:error, reason.(reason)}
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
    {:ok, value} ->
      value = item
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
  end
  def to_option(result) do
    (case result do
      {:ok, value} ->
        _some = value
        {:some, value}
      {:error, __reason} -> {:none}
    end)
  end
end
