defmodule Elixir.Otp.RestartType do
  def permanent() do
    {:Permanent}
  end
  def temporary() do
    {:Temporary}
  end
  def transient() do
    {:Transient}
  end
end