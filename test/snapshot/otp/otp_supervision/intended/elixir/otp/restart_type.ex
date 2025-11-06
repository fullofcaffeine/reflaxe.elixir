defmodule Elixir.Otp.RestartType do
  def permanent() do
    {:permanent}
  end
  def temporary() do
    {:temporary}
  end
  def transient() do
    {:transient}
  end
end
