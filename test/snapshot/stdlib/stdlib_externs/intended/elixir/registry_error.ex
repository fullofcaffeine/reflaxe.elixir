defmodule elixir.RegistryError do
  def already_registered(arg0) do
    {:AlreadyRegistered, arg0}
  end
  def error(arg0) do
    {:Error, arg0}
  end
end