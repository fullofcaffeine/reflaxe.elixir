defmodule OptionTools do
  def map(_option, transform) do
    case (_option) do
      {:some, g} ->
        g = elem(_option, 1)
        value = g
        transform.(g)
      {:none} ->
        :none
    end
  end
  def then(_option, transform) do
    case (_option) do
      {:some, g} ->
        g = elem(_option, 1)
        value = g
        transform.(g)
      {:none} ->
        :none
    end
  end
  def flat_map(option, transform) do
    then(option, transform)
  end
  def flatten(_option) do
    case (_option) do
      {:some, g} ->
        g = elem(_option, 1)
        inner = g
        g
      {:none} ->
        :none
    end
  end
  def filter(_option, predicate) do
    case (_option) do
      {:some, g} ->
        g = elem(_option, 1)
        value = g
        if (predicate.(g)), do: g, else: :none
      {:none} ->
        :none
    end
  end
  def unwrap(_option, default_value) do
    case (_option) do
      {:some, g} ->
        g = elem(_option, 1)
        value = g
        g
      {:none} ->
        default_value
    end
  end
  def lazy_unwrap(_option, fn_param) do
    case (_option) do
      {:some, g} ->
        g = elem(_option, 1)
        value = g
        g
      {:none} ->
        fn_param.()
    end
  end
  def or_fn(first, second) do
    case (first) do
      {:some, g} ->
        _g = elem(first, 1)
        first
      {:none} ->
        second
    end
  end
  def lazy_or(first, fn_param) do
    case (first) do
      {:some, g} ->
        _g = elem(first, 1)
        first
      {:none} ->
        fn_param.()
    end
  end
  def is_some(_option) do
    case (_option) do
      {:some, g} ->
        _g = elem(_option, 1)
        true
      {:none} ->
        false
    end
  end
  def is_none(_option) do
    case (_option) do
      {:some, g} ->
        _g = elem(_option, 1)
        false
      {:none} ->
        true
    end
  end
  def all(options) do
    values = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {options, g, :ok}, fn _, {acc_options, acc_g, acc_state} ->
  if (acc_g < length(acc_options)) do
    option = options[g]
    acc_g = acc_g + 1
    nil
    {:cont, {acc_options, acc_g, acc_state}}
  else
    {:halt, {acc_options, acc_g, acc_state}}
  end
end)
    {:some, values}
  end
  def values(options) do
    result = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {options, g, :ok}, fn _, {acc_options, acc_g, acc_state} ->
  if (acc_g < length(acc_options)) do
    option = options[g]
    acc_g = acc_g + 1
    nil
    {:cont, {acc_options, acc_g, acc_state}}
  else
    {:halt, {acc_options, acc_g, acc_state}}
  end
end)
    result
  end
  def to_result(_option, error) do
    case (_option) do
      {:some, g} ->
        g = elem(_option, 1)
        value = g
        g
      {:none} ->
        error
    end
  end
  def from_result(_result) do
    case (_result) do
      {:ok, g} ->
        g = elem(_result, 1)
        value = g
        g
      {:error, g} ->
        _g = elem(_result, 1)
        :none
    end
  end
  def from_nullable(value) do
    if (value != nil), do: value, else: :none
  end
  def to_nullable(_option) do
    case (_option) do
      {:some, g} ->
        g = elem(_option, 1)
        value = g
        g
      {:none} ->
        nil
    end
  end
  def to_reply(_option) do
    case (_option) do
      {:some, g} ->
        g = elem(_option, 1)
        value = g
        %{:reply => g, :status => "ok"}
      {:none} ->
        %{:reply => nil, :status => "none"}
    end
  end
  def expect(_option, _message) do
    case (_option) do
      {:some, g} ->
        g = elem(_option, 1)
        value = g
        g
      {:none} ->
        throw("Expected Some value but got None: " <> _message)
    end
  end
  def some(value) do
    {:some, value}
  end
  def none() do
    :none
  end
  def apply(option, fn_param) do
    case (option) do
      {:some, g} ->
        g = elem(option, 1)
        value = g
        fn_param.(g)
      {:none} ->
        nil
    end
    option
  end
end