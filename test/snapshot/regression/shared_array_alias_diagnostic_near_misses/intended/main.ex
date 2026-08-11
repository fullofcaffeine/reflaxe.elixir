defmodule Main do
  def same_binding() do
    values = [1]
    _alias = values
    values = values ++ [2]
    length(values)
  end
  def read_before_mutation() do
    values = [1]
    _alias = values
    values = values ++ [2]
    length(values)
  end
  def overwritten_alias() do
    values = [1]
    _alias = values
    _ = values ++ [2]
    alias_ = []
    length(alias_)
  end
  def branch_uncertainty(flag) do
    values = [1]
    alias = values
    _ = if (flag), do: values ++ [2], else: values
    length(alias)
  end
  def branch_observation_uncertainty(flag) do
    values = [1]
    _alias = values
    values = values ++ [2]
    if (flag), do: nil
    length(values)
  end
  def escape_uncertainty() do
    values = [1]
    alias = values
    observe(values)
    _ = values ++ [2]
    length(alias)
  end
  def functional_flow() do
    values = [1]
    _alias = values
    values = values ++ [2]
    length(values)
  end
  def nested_overwrite() do
    values = [1]
    _alias = values
    _ = values ++ [2]
    alias_ = []
    length(alias_)
  end
  def push_argument_reference() do
    values = [1]
    alias = values
    values = values ++ [length(alias)]
    length(values)
  end
  def unused_closure() do
    values = [1]
    alias = values
    values = values ++ [2]
    _read_later = fn -> length(alias) end
    length(values)
  end
  def escape_before_alias() do
    values = [1]
    observe(values)
    alias = values
    _ = values ++ [2]
    length(alias)
  end
  defp observe(_values) do

  end
  def main() do
    nil
  end
end
