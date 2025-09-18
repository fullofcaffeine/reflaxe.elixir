defmodule Elixir.Otp.ApplicationResult do
  def ok(arg0) do
    {0, arg0}
  end
  def error(arg0) do
    {1, arg0}
  end
  def ignore() do
    {2}
  end
end