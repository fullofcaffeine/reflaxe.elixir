defmodule ResultTools do
  def map(result, transform) do
    (case result do
      {:ok, value} -> {:ok, value.(value)}
      {:error, error} -> {:error, error}
    end)
  end
  def flat_map(result, transform) do
    (case result do
      {:ok, value} ->
        value.(value)
      {:error, error} -> {:error, error}
    end)
  end
  def bind(result, transform) do
    flat_map(result, transform)
  end
  def fold(result, on_success, on_error) do
    (case result do
      {:ok, value} ->
        value.(value)
      {:error, _error} ->
        on_error.(on_error)
    end)
  end
  def is_ok(result) do
    (case result do
      {:ok, _value} -> true
      {:error, _error} -> false
    end)
  end
  def is_error(result) do
    (case result do
      {:ok, _value} -> false
      {:error, _error} -> true
    end)
  end
  def unwrap(result) do
    (case result do
      {:ok, value} -> value
      {:error, _error} -> throw("Attempted to unwrap Error result: " <> inspect(error))
    end)
  end
  def unwrap_or(result, default_value) do
    (case result do
      {:ok, value} ->
        default_value = value
        default_value
      {:error, payload} -> payload
    end)
  end
  def unwrap_or_else(result, error_handler) do
    (case result do
      {:ok, value} -> value
      {:error, error} ->
        error.(error)
    end)
  end
  def filter(result, predicate, error_value) do
    (case result do
      {:ok, value} ->
        error_value = value
        if (error_value.(error_value)), do: {:ok, error_value}, else: {:error, error_value}
      {:error, error} -> {:error, error}
    end)
  end
  def map_error(result, transform) do
    (case result do
      {:ok, value} -> {:ok, value}
      {:error, error} -> {:error, error.(error)}
    end)
  end
  def bimap(result, on_success, on_error) do
    (case result do
      {:ok, value} -> {:ok, value.(value)}
      {:error, _error} -> {:error, on_error.(on_error)}
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
    _ = Enum.each(results, (fn -> fn result ->
    (case result do
    {:ok, value} ->
      result = Enum.concat(result, [value])
    {:error, error} ->
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
      {:ok, value} -> {:some, value}
      {:error, _error} -> {:none}
    end)
  end
end
