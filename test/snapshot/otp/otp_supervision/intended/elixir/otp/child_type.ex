defmodule Elixir.Otp.ChildType do
  def worker() do
    {:worker}
  end
  def supervisor() do
    {:supervisor}
  end
end
