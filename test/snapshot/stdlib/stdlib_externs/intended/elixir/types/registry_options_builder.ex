defmodule RegistryOptionsBuilder do
  def unique(name) do
    %{:keys => {:unique}, :name => String.to_atom(name)}
  end
  def duplicate(name) do
    %{:keys => {:duplicate}, :name => String.to_atom(name)}
  end
  def with_partitions(options, partitions) do
    partitions = partitions
    options
  end
  def with_compression(options) do
    compressed = true
    options
  end
  def with_meta(options, key, value) do
    if (Map.get(options, :meta) == nil) do
      meta = []
    end
    options.meta ++ [%{:key => key, :value => value}]
    options
  end
end