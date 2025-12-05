defmodule ResultTools do
  def map(result, transform) do
    (case result do
      {:ok, ^transform} -> {:ok, transform.(transform)}
      {:error, value} -> {:error, value}
    end)
  end
  def flat_map(result, transform) do
    (case result do
      {:ok, ^transform} -> value = transform.(transform)
      {:error, value} -> {:error, value}
    end)
  end
  def bind(result, transform) do
    flat_map(result, transform)
  end
  def fold(result, on_success, on_error) do
    (case result do
      {:ok, ^on_success} -> value = on_success.(on_success)
      {:error, ^on_error} -> value = on_error.(value)
    end)
  end
  def is_ok(result) do
    (case result do
      {:ok, _value} ->
        true = _value
        true
      {:error, __value} -> false
    end)
  end
  def is_error(result) do
    (case result do
      {:ok, _value} ->
        false = _value
        false
      {:error, __value} -> true
    end)
  end
  def unwrap(result) do
    (case result do
      {:ok, value} -> value
      {:error, __value} -> throw("Attempted to unwrap Error result: " <> inspect(error))
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
      {:error, ^error_handler} -> value = error_handler.(value)
    end)
  end
  def filter(result, _predicate, error_value) do
    (case result do
      {:ok, value} ->
        error_value = value
        if (error_value.(error_value)), do: {:ok, error_value}, else: {:error, error_value}
      {:error, _value} -> {:error, error_value}
    end)
  end
  def map_error(result, transform) do
    (case result do
      {:ok, value} ->
        ok = value
        {:ok, value}
      {:error, ^transform} -> {:error, transform.(value)}
    end)
  end
  def bimap(result, on_success, on_error) do
    (case result do
      {:ok, ^on_success} -> {:ok, on_success.(on_success)}
      {:error, ^on_error} -> {:error, on_error.(value)}
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
  end
  def to_option(result) do
    (case result do
      {:ok, value} ->
        some = value
        {:some, value}
      {:error, __value} -> {:none}
    end)
  end
end
