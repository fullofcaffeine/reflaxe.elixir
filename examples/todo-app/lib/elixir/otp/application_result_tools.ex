defmodule ApplicationResultTools do
  def ok(state) do
    {:Ok, state}
  end
  def error(reason) do
    {:Error, reason}
  end
  def ignore() do
    :ignore
  end
end