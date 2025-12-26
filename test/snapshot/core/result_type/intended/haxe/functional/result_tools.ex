defmodule ResultTools do
  def map(result, transform) do
    (case result do
      {:ok, value} -> {:ok, value.(value)}
      {:error, error} -> {:error, error}
    end)
  end
  def flat_map(result, transform) do
    (case result do
      {:ok, value} -> _ = value.(value)
      {:error, error} -> {:error, error}
    end)
  end
  def bind(result, transform) do
    flat_map(result, transform)
  end
  def fold(result, on_success, on_error) do
    (case result do
      {:ok, value} -> _ = value.(value)
      {:error, error} -> _ = on_error.(error)
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
      {:ok, value} -> value
      {:error, _error} -> default_value
    end)
  end
  def unwrap_or_else(result, error_handler) do
    (case result do
      {:ok, value} -> value
      {:error, error} -> _ = error_handler.(error)
    end)
  end
  def filter(result, predicate, error_value) do
    (case result do
      {:ok, value} -> if (value.(value)), do: {:ok, value}, else: {:error, value}
      {:error, error} -> {:error, error}
    end)
  end
  def map_error(result, transform) do
    (case result do
      {:ok, value} -> {:ok, value}
      {:error, error} -> {:error, transform.(error)}
    end)
  end
  def bimap(result, on_success, on_error) do
    (case result do
      {:ok, value} -> {:ok, value.(value)}
      {:error, error} -> {:error, on_error.(error)}
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
    _g = 0
    _ = Enum.each(results, fn result ->
  (case result do
    {:ok, value} -> values = values ++ [value]
    {:error, error} -> {:error, error}
  end)
end)
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
