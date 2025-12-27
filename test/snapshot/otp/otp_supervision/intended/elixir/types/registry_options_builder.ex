defmodule RegistryOptionsBuilder do
  def unique(name) do
    %{:keys => {:unique}, :name => String.to_atom(name)}
  end
  def duplicate(name) do
    %{:keys => {:duplicate}, :name => String.to_atom(name)}
  end
  def with_partitions(options, partitions) do
    options = Map.put(options, "partitions", partitions)
    options
  end
  def with_compression(options) do
    options = Map.put(options, "compressed", true)
    options
  end
  def with_meta(options, key, value) do
    options = if (Kernel.is_nil(options.meta)) do
      Map.put(options, "meta", [])
    else
      options
    end
    options.meta ++ [%{:key => key, :value => value}]
    options
  end
end
