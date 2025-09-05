defmodule OptionTools do
  def map(option, transform) do
    case (option.elem(0)) do
      0 ->
        g = option.elem(1)
        value = g
        {:Some, transform.(value)}
      1 ->
        :none
    end
  end
  def then(option, transform) do
    case (option.elem(0)) do
      0 ->
        g = option.elem(1)
        value = g
        {:ModuleRef, value}
      1 ->
        :none
    end
  end
  def flatten(option) do
    case (option.elem(0)) do
      0 ->
        g = option.elem(1)
        inner = g
        inner
      1 ->
        :none
    end
  end
  def filter(option, predicate) do
    case (option.elem(0)) do
      0 ->
        g = option.elem(1)
        value = g
        if (predicate.(value)), do: {:Some, value}, else: :none
      1 ->
        :none
    end
  end
  def unwrap(option, default_value) do
    case (option.elem(0)) do
      0 ->
        g = option.elem(1)
        value = g
        value
      1 ->
        default_value
    end
  end
  def lazy_unwrap(option, fn) do
    case (option.elem(0)) do
      0 ->
        g = option.elem(1)
        value = g
        value
      1 ->
        fn.()
    end
  end
  def or(first, second) do
    case (first.elem(0)) do
      0 ->
        _g = first.elem(1)
        first
      1 ->
        second
    end
  end
  def lazy_or(first, fn) do
    case (first.elem(0)) do
      0 ->
        _g = first.elem(1)
        first
      1 ->
        {:ModuleRef}
    end
  end
  def is_some(option) do
    case (option.elem(0)) do
      0 ->
        _g = option.elem(1)
        true
      1 ->
        false
    end
  end
  def is_none(option) do
    case (option.elem(0)) do
      0 ->
        _g = option.elem(1)
        false
      1 ->
        true
    end
  end
  def all(options) do
    values = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, options, :ok}, fn _, {acc_g, acc_options, acc_state} ->
  if (acc_g < acc_options.length) do
    option = options[g]
    acc_g = acc_g + 1
    case (option.elem(0)) do
      0 ->
        acc_g = option.elem(1)
        value = acc_g
        values.push(value)
      1 ->
        :none
    end
    {:cont, {acc_g, acc_options, acc_state}}
  else
    {:halt, {acc_g, acc_options, acc_state}}
  end
end)
    {:Some, values}
  end
  def values(options) do
    result = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, options, :ok}, fn _, {acc_g, acc_options, acc_state} ->
  if (acc_g < acc_options.length) do
    option = options[g]
    acc_g = acc_g + 1
    case (option.elem(0)) do
      0 ->
        acc_g = option.elem(1)
        value = acc_g
        result.push(value)
      1 ->
        nil
    end
    {:cont, {acc_g, acc_options, acc_state}}
  else
    {:halt, {acc_g, acc_options, acc_state}}
  end
end)
    result
  end
  def to_result(option, error) do
    case (option.elem(0)) do
      0 ->
        g = option.elem(1)
        value = g
        {:Ok, value}
      1 ->
        {:Error, error}
    end
  end
  def from_result(result) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        {:Some, value}
      1 ->
        _g = result.elem(1)
        :none
    end
  end
  def from_nullable(value) do
    if (value != nil), do: {:Some, value}, else: :none
  end
  def to_nullable(option) do
    case (option.elem(0)) do
      0 ->
        g = option.elem(1)
        value = g
        value
      1 ->
        nil
    end
  end
  def to_reply(option) do
    case (option.elem(0)) do
      0 ->
        g = option.elem(1)
        value = g
        %{:reply => value, :status => "ok"}
      1 ->
        %{:reply => nil, :status => "none"}
    end
  end
  def expect(option, _message) do
    case (option.elem(0)) do
      0 ->
        g = option.elem(1)
        value = g
        value
      1 ->
        throw("Expected Some value but got None: " <> message)
    end
  end
  def apply(option, fn) do
    case (option.elem(0)) do
      0 ->
        g = option.elem(1)
        value = g
        fn.(value)
      1 ->
        nil
    end
    option
  end
end