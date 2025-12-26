defmodule OptionTools do
  def map(option, transform) do
    (case option do
      {:some, value} -> {:some, transform.(value)}
      {:none} -> {:none}
    end)
  end
  def then(option, transform) do
    (case option do
      {:some, value} -> _ = transform.(value)
      {:none} -> {:none}
    end)
  end
  def flat_map(option, transform) do
    then(option, transform)
  end
  def flatten(option) do
    (case option do
      {:some, inner} -> inner
      {:none} -> {:none}
    end)
  end
  def filter(option, predicate) do
    (case option do
      {:some, value} -> if (predicate.(value)), do: {:some, value}, else: {:none}
      {:none} -> {:none}
    end)
  end
  def unwrap(option, default_value) do
    (case option do
      {:some, value} -> value
      {:none} -> default_value
    end)
  end
  def lazy_unwrap(option, fn_param) do
    (case option do
      {:some, value} -> value
      {:none} ->
        fn_param.()
    end)
  end
  def or_fn(first, second) do
    (case first do
      {:some, v} -> v
      {:none} -> second
    end)
  end
  def lazy_or(first, fn_param) do
    (case first do
      {:some, v} -> v
      {:none} ->
        fn_param.()
    end)
  end
  def is_some(option) do
    (case option do
      {:some, _v} -> true
      {:none} -> false
    end)
  end
  def is_none(option) do
    (case option do
      {:some, _v} -> false
      {:none} -> true
    end)
  end
  def all(options) do
    values = []
    _g = 0
    _ = Enum.each(options, (fn -> fn option ->
  (case option do
    {:some, value} -> values = values ++ [value]
    {:none} -> {:none}
  end)
end end).())
    {:some, values}
  end
  def values(options) do
    _g = 0
    _ = Enum.each(options, (fn -> fn option ->
  (case option do
    {:some, value} -> result = result ++ [value]
    {:none} -> nil
  end)
end end).())
    []
  end
  def to_result(option, error) do
    (case option do
      {:some, value} -> {:ok, value}
      {:none} -> {:error, error}
    end)
  end
  def from_result(result) do
    (case result do
      {:ok, value} -> {:some, value}
      {:error, _error} -> {:none}
    end)
  end
  def from_nullable(value) do
    if (not Kernel.is_nil(value)), do: {:some, value}, else: {:none}
  end
  def to_nullable(option) do
    (case option do
      {:some, value} -> value
      {:none} -> nil
    end)
  end
  def to_reply(option, none_error) do
    (case option do
      {:some, value} -> {:ok, value}
      {:none} -> {:error, none_error}
    end)
  end
  def expect(option, message) do
    (case option do
      {:some, value} -> value
      {:none} -> throw("Expected Some value but got None: " <> message)
    end)
  end
  def some(value) do
    {:some, value}
  end
  def none() do
    {:none}
  end
  def apply(option, fn_param) do
    (case option do
      {:some, value} -> _ = fn_param.(value)
      {:none} -> nil
    end)
    option
  end
end
