defmodule Elixir.Otp.ApplicationStartType do
  def normal() do
    {:normal}
  end
  def temporary() do
    {:temporary}
  end
  def permanent() do
    {:permanent}
  end
end
