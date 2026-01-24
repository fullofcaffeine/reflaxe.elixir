defmodule Main do
  def main() do
    d = DateTime.utc_now()
    iso = (case d do
  %NaiveDateTime{} = nd -> NaiveDateTime.to_iso8601(nd)
  %DateTime{} = dt -> DateTime.to_iso8601(dt)
  other -> Kernel.to_string(other)
end)
    parsed = iso
    _ = Log.trace(inspect(%{:iso => iso, :y => parsed.year, :m => (parsed.month - 1), :dd => parsed.day}), nil)
  end
end
