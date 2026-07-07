defmodule ResultTools do
  def map(result, transform) do
    (case result do
      {:ok, value} -> {:ok, transform.(value)}
      {:error, error} -> {:error, error}
    end)
  end
  def flat_map(result, transform) do
    (case result do
      {:ok, value} ->
        transform.(value)
      {:error, error} -> {:error, error}
    end)
  end
  def bind(result, transform) do
    flat_map(result, transform)
  end
  def fold(result, on_success, on_error) do
    (case result do
      {:ok, value} ->
        on_success.(value)
      {:error, error} ->
        on_error.(error)
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
      {:error, error} -> raise Reflaxe.Elixir.HaxeThrow, [value: "Attempted to unwrap Error result: " <> Reflaxe.Elixir.HaxeFloat.to_string(error)]
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
      {:error, error} ->
        error_handler.(error)
    end)
  end
  def filter(result, predicate, error_value) do
    (case result do
      {:ok, value} ->
        if (predicate.(value)), do: {:ok, value}, else: {:error, error_value}
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
      {:ok, value} -> {:ok, on_success.(value)}
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
    (case Enum.reduce_while(results, {:__reflaxe_continue__, values}, fn result, {:__reflaxe_continue__, values_acc} ->
  (case (case result do
  {:ok, value} ->
    values_acc = values_acc ++ [value]
    {:cont, {:__reflaxe_continue__, values_acc}}
  {:error, error} -> {:halt, {:__reflaxe_return__, {:error, error}}}
end) do
    {:halt, reflaxe_halt_payload} -> {:halt, reflaxe_halt_payload}
    {:cont, {:__reflaxe_continue__, values_acc}} -> {:cont, {:__reflaxe_continue__, values_acc}}
  end)
end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, reflaxe_continue_values} ->
        values = reflaxe_continue_values
        {:ok, values}
    end)
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
