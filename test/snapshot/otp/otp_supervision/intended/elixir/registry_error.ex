defmodule Elixir.RegistryError do
  def already_registered(arg0) do
    {0, arg0}
  end
  def error(arg0) do
    {1, arg0}
  end
end
