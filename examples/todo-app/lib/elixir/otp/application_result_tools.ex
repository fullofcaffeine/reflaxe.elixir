defmodule ApplicationResultTools do
  def ok() do
    fn state -> {:Ok, state} end
  end
  def error() do
    fn reason -> {:Error, reason} end
  end
  def ignore() do
    fn -> :Ignore end
  end
end