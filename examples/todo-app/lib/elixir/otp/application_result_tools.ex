defmodule ApplicationResultTools do
  def ok(state) do
    fn state -> {:Ok, state} end
  end
  def error(reason) do
    fn reason -> {:Error, reason} end
  end
  def ignore() do
    fn -> :Ignore end
  end
end