defmodule Main do
  def main() do
    
  end
  def test_utc_now() do
    DateTime.to_iso8601(DateTime.utc_now())
  end
  def passthrough(s) do
    this1 = s
    case this1 do
  %NaiveDateTime{} = nd -> NaiveDateTime.to_iso8601(nd)
  %DateTime{} = dt -> DateTime.to_iso8601(dt)
  other -> Kernel.to_string(other)
end
  end
end
