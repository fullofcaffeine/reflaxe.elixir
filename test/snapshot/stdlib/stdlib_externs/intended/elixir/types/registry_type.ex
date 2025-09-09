defmodule elixir.types.RegistryType do
  def unique() do
    {:Unique}
  end
  def duplicate() do
    {:Duplicate}
  end
end