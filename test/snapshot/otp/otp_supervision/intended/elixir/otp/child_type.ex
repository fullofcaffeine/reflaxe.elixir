defmodule elixir.otp.ChildType do
  def worker() do
    {:Worker}
  end
  def supervisor() do
    {:Supervisor}
  end
end