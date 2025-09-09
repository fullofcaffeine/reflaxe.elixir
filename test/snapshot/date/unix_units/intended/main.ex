defmodule Main do
  def main() do
    this1 = DateTime.utc_now()
    t = this1.to_unix("millisecond")
    d2 = DateTime.from_unix!(Std.int(t), "millisecond")
    t2 = d2.to_unix("millisecond")
    Log.trace(Std.string(%{:t => t, :t2 => t2}), nil)
  end
end