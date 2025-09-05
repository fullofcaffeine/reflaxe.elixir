defmodule Elixir.Types.RegistryType do
  def unique() do
    {:Unique}
  end
  def duplicate() do
    {:Duplicate}
  end
end