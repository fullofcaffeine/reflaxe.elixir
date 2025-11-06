defmodule Elixir.Otp.ShutdownType do
  def brutal() do
    {:brutal}
  end
  def timeout(arg0) do
    {:timeout, arg0}
  end
  def infinity() do
    {:infinity}
  end
end
