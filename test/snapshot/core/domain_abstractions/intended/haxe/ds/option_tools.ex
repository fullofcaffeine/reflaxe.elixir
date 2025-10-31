defmodule OptionTools do
  def map(option, transform) do
    (case option do
      {:some, transform} ->
        transform.(transform)
      {:none} -> {:none}
    end)
  end
  def then(option, transform) do
    (case option do
      {:some, transform} ->
        transform.(transform)
      {:none} -> {:none}
    end)
  end
  def flat_map(option, transform) do
    then(option, transform)
  end
  def flatten(option) do
    (case option do
      {:some, value} -> value
      {:none} -> {:none}
    end)
  end
  def filter(option, predicate) do
    (case option do
      {:some, value} when predicate.(value) -> value
      {:some, value} -> {:none}
      {:none} -> {:none}
    end)
  end
  def unwrap(option, default_value) do
    (case option do
      {:some, value} ->
        default_value = default_value
        default_value
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
      {:some, value} ->
        first = value
        first
      {:none} -> second
    end)
  end
  def lazy_or(first, fn_param) do
    (case first do
      {:some, value} ->
        first = value
        first
      {:none} ->
        fn_param.()
    end)
  end
  def is_some(option) do
    (case option do
      {:some, value} -> true
      {:none} -> false
    end)
  end
  def is_none(option) do
    (case option do
      {:some, value} -> false
      {:none} -> true
    end)
  end
  def all(options) do
    Enum.reduce(options, [], fn item, acc ->
      acc = Enum.concat(acc, [item])
  {:none} -> {:none}
end)
      acc
    end)
  end
  def values(options) do
    Enum.each(options, fn item ->
            (case item do
        {:some, result} ->
          item = Enum.concat(item, [item])
        {:none} -> nil
      end)
    end)
    []
  end
  def to_result(option, error) do
    (case option do
      {:some, value} -> value
      {:none} -> error
    end)
  end
  def from_result(result) do
    (case result do
      {:ok, value} -> value
      {:error, value} -> {:none}
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
      {:some, fn_param} ->
        fn_param.(fn_param)
      {:none} -> nil
    end)
    option
  end
end
