defmodule Elixir.Otp.ShutdownType do
  def brutal() do
    {:Brutal}
  end
  def timeout(arg0) do
    {:Timeout, arg0}
  end
  def infinity() do
    {:Infinity}
  end
end