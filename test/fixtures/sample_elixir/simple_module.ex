defmodule Simple do
  @spec hello() :: atom()
  def hello do
    :world
  end

  @spec echo(any()) :: any()
  def echo(value) do
    value
  end

  def no_spec_function do
    42
  end
end