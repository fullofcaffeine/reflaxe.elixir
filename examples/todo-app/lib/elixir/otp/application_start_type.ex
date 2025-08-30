defmodule ApplicationStartType do
  def normal() do
    {:Normal}
  end
  def temporary() do
    {:Temporary}
  end
  def permanent() do
    {:Permanent}
  end
end