defmodule Main do
  def main() do
    t = DateTime.to_iso8601(DateTime.utc_now())
    d2 = Date_Impl_.from_time(t)
    t_value = d2
    _ = Log.trace(Reflaxe.Elixir.HaxeFloat.to_string(%{:t => t, :t2 => t_value}), nil)
  end
end
