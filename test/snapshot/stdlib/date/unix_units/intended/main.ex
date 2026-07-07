defmodule Main do
  def main() do
    t = DateTime.to_unix(DateTime.utc_now(), :millisecond)
    d2 = DateTime.from_unix!(trunc(t), :millisecond)
    t_value = DateTime.to_unix(d2, :millisecond)
    _ = Log.trace(Reflaxe.Elixir.HaxeFloat.to_string(%{t: t, t2: t_value}), nil)
  end
end
