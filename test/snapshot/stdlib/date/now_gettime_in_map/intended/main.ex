defmodule Main do
  def main() do
    meta = %{online_at: DateTime.to_iso8601(DateTime.utc_now()), user_name: "bob"}
    _ = Log.trace(Reflaxe.Elixir.HaxeFloat.to_string(meta), nil)
  end
end
