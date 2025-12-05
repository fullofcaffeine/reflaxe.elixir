defmodule OptionTools do
  def map(option, _transform) do
    (case option do
      {:some, value} -> {:some, value.(value)}
      {:none} -> {:none}
    end)
  end
  def then(option, _transform) do
    (case option do
      {:some, value} ->
        value.(value)
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
  def filter(option, _predicate) do
    (case option do
      {:some, _value} ->
        cond do
          value.(value) -> {:some, value}
          true -> {:none}
        end
      {:none} -> {:none}
    end)
  end
  def unwrap(option, default_value) do
    (case option do
      {:some, _value} -> default_value
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
      {:some, value} -> value
      {:none} -> second
    end)
  end
  def lazy_or(first, fn_param) do
    (case first do
      {:some, value} -> value
      {:none} ->
        fn_param.()
    end)
  end
  def is_some(option) do
    (case option do
      {:some, ^option} -> true
      {:none} -> false
    end)
  end
  def is_none(option) do
    (case option do
      {:some, ^option} -> false
      {:none} -> true
    end)
  end
  def all(options) do
    values = []
    _ = Enum.each(options, (fn -> fn item ->
    (case item do
    {:some, value} ->
      item = Enum.concat(item, [item])
    {:none} -> {:none}
  end)
end end).())
    {:some, values}
  end
  def values(options) do
    _ = Enum.each(options, (fn -> fn item ->
    (case item do
    {:some, value} ->
      item = Enum.concat(item, [item])
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
      {:ok, value} ->
        some = value
        {:some, value}
      {:error, __value} -> {:none}
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
  def to_reply(option) do
    (case option do
      {:some, value} -> %{:reply => value, :status => "ok"}
      {:none} -> %{:reply => nil, :status => "none"}
    end)
  end
  def expect(option, _message) do
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
      {:some, ^fn_param} ->
        fn_param.(fn_)
      {:none} -> nil
    end)
    option
  end
end
