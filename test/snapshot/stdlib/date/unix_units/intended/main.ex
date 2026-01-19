defmodule Main do
  def main() do
    t = DateTime.to_iso8601(DateTime.utc_now())
    d2 = Date_Impl_.from_time(t)
    t = d2
    _ = Log.trace(inspect(%{:t => t, :t2 => t_value}), nil)
  end
end
