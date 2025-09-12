defmodule Elixir.Otp.RestartType do
  def permanent() do
    {0}
  end
  def temporary() do
    {1}
  end
  def transient() do
    {2}
  end
end