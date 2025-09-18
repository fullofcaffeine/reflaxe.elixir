defmodule Elixir.Otp.ApplicationStartType do
  def normal() do
    {0}
  end
  def temporary() do
    {1}
  end
  def permanent() do
    {2}
  end
end