defmodule Elixir.Otp.ShutdownType do
  def brutal() do
    {0}
  end
  def timeout(arg0) do
    {1, arg0}
  end
  def infinity() do
    {2}
  end
end