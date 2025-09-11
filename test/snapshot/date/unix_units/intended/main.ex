defmodule Main do
  def main() do
    t = Date_Impl_.get_time(DateTime.utc_now())
    d2 = DateTime.from_unix!(Std.int(t), "millisecond")
    t2 = Date_Impl_.get_time(d2)
    Log.trace(Std.string(%{:t => t, :t2 => t2}), nil)
  end
end